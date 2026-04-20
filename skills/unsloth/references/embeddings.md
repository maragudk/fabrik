# Embedding fine-tuning

Unsloth supports first-class fine-tuning of encoder-style models through `FastSentenceTransformer`. Reported speedups: 1.8-3.3x faster and ~20% less VRAM than FA2 SentenceTransformers, with 2x longer usable context. EmbeddingGemma-300M fits QLoRA training in about 3 GB of VRAM.

## Supported models

Pre-uploaded to the `unsloth/` org:

- `unsloth/all-MiniLM-L6-v2`, `unsloth/all-mpnet-base-v2`
- `unsloth/bge-m3`
- `unsloth/embeddinggemma-300m`
- `unsloth/Qwen3-Embedding-0.6B`, `unsloth/Qwen3-Embedding-4B`
- `unsloth/gte-modernbert-base`

Also works out-of-the-box against upstream: `BAAI/bge-large-en-v1.5`, `BAAI/bge-reranker-v2-m3`, `intfloat/e5-large-v2`, `intfloat/multilingual-e5-large-instruct`, `mixedbread-ai/mxbai-embed-large-v1`, `Snowflake/snowflake-arctic-embed-l-v2.0`, `answerdotai/ModernBERT-base`, `answerdotai/ModernBERT-large`, `Alibaba-NLP/gte-modernbert-base`.

Caveat: models missing a `modules.json` get default SentenceTransformers pooling assigned — double-check the pooled output shape if you use custom pooling. MPNet and DistilBERT need `unsloth`/`transformers` recent enough to include gradient-checkpointing patches.

## Target-module map

`get_peft_model` needs `target_modules` matched to the architecture family:

- BERT/MiniLM/BGE-M3/MPNet: `["key", "query", "value", "dense"]`
- EmbeddingGemma / Qwen3-Embedding / ModernBERT: `["q_proj","k_proj","v_proj","o_proj","gate_proj","up_proj","down_proj"]`

Always set `task_type="FEATURE_EXTRACTION"` for embedding PEFT (vs `"SEQ_CLS"` for classifiers).

## Loss choice

- `MultipleNegativesRankingLoss` (MNRL): default for `{anchor, positive}` pairs. Scales with batch size — more items in the batch means more and harder in-batch negatives.
- `CachedMultipleNegativesRankingLoss`: MNRL without the batch-size/memory tradeoff. Use when you want an effective batch of 1024+ but VRAM only fits 128.
- `TripletLoss`: for `{anchor, positive, negative}` triplets with explicit hard negatives.
- `CoSENTLoss`, `AnglELoss`: regression-style supervision when you have graded similarity scores (`{sentence1, sentence2, score}`).

`BatchSamplers.NO_DUPLICATES` with MNRL-family losses — duplicate anchors or positives inside one batch become false in-batch negatives and silently hurt training.

## Canonical training (BGE-M3 / MiniLM shape)

```python
from unsloth import FastSentenceTransformer, is_bf16_supported

model = FastSentenceTransformer.from_pretrained(
    model_name = "unsloth/bge-m3",
    max_seq_length = 512,
    full_finetuning = False,
)

model = FastSentenceTransformer.get_peft_model(
    model,
    r = 32, lora_alpha = 64, lora_dropout = 0, bias = "none",
    target_modules = ["key", "query", "value", "dense"],
    use_gradient_checkpointing = False,
    task_type = "FEATURE_EXTRACTION",
    random_state = 3407,
)

from datasets import load_dataset
dataset = load_dataset("sentence-transformers/all-nli", "pair", split="train[:100000]")

from sentence_transformers import SentenceTransformerTrainer, SentenceTransformerTrainingArguments, losses
from sentence_transformers.training_args import BatchSamplers

trainer = SentenceTransformerTrainer(
    model = model,
    train_dataset = dataset,
    loss = losses.MultipleNegativesRankingLoss(model),
    args = SentenceTransformerTrainingArguments(
        output_dir = "bge_m3_out",
        num_train_epochs = 2,
        per_device_train_batch_size = 256,
        learning_rate = 3e-5,
        warmup_ratio = 0.03,
        lr_scheduler_type = "constant_with_warmup",
        bf16 = is_bf16_supported(),
        fp16 = not is_bf16_supported(),
        batch_sampler = BatchSamplers.NO_DUPLICATES,
        logging_steps = 50,
        report_to = "none",
    ),
)
trainer.train()
```

## EmbeddingGemma (different target modules + built-in prompts)

EmbeddingGemma expects `prompts={"query": ..., "document": ...}` so training applies the same instruction templates used at inference time.

```python
model = FastSentenceTransformer.from_pretrained(
    model_name = "unsloth/embeddinggemma-300m",
    max_seq_length = 1024,
    full_finetuning = False,
)

model = FastSentenceTransformer.get_peft_model(
    model,
    r = 32, lora_alpha = 64, lora_dropout = 0, bias = "none",
    target_modules = ["q_proj","k_proj","v_proj","o_proj",
                      "gate_proj","up_proj","down_proj"],
    use_gradient_checkpointing = "unsloth",
    task_type = "FEATURE_EXTRACTION",
    random_state = 3407,
)

args = SentenceTransformerTrainingArguments(
    output_dir = "embgemma_out",
    num_train_epochs = 1,
    per_device_train_batch_size = 128,
    learning_rate = 2e-5,
    warmup_ratio = 0.05,
    lr_scheduler_type = "constant_with_warmup",
    bf16 = is_bf16_supported(),
    fp16 = not is_bf16_supported(),
    batch_sampler = BatchSamplers.NO_DUPLICATES,
    prompts = {                                  # apply the model's built-in instruction prompts
        "question":      model.prompts["query"],
        "passage_text":  model.prompts["document"],
    },
    logging_steps = 50,
    report_to = "none",
)
```

## Information retrieval evaluator

Add an IR evaluator to watch recall/MRR/NDCG instead of just loss.

```python
from sentence_transformers.evaluation import InformationRetrievalEvaluator

evaluator = InformationRetrievalEvaluator(
    queries = queries,                # dict[str, str] — qid -> query text
    corpus = corpus,                  # dict[str, str] — docid -> passage
    relevant_docs = relevant_docs,    # dict[str, set[str]] — qid -> {relevant docids}
    show_progress_bar = False,
    batch_size = 64,
)

# Pass through to SentenceTransformerTrainer:
args = SentenceTransformerTrainingArguments(
    ...,
    eval_strategy = "steps",
    eval_steps = 200,
)
trainer = SentenceTransformerTrainer(
    model=model, train_dataset=dataset, loss=loss, evaluator=evaluator, args=args,
)
```

For synthetic IR benchmarks, NanoBEIR is the lightweight standard; `sbert.net`'s `training_gooaq_unsloth.py` has a reference implementation.

## Reloading for inference

The single biggest gotcha. After training, reload with `for_inference=True`:

```python
model = FastSentenceTransformer.from_pretrained("bge_m3_out", for_inference=True)
embeddings = model.encode(["hello", "world"])
```

Without `for_inference=True`, the model silently emits wrong (untransformed) vectors. In production downstream of `save_pretrained_merged`, you can drop Unsloth entirely:

```python
from sentence_transformers import SentenceTransformer
model = SentenceTransformer("path_or_hub_repo")   # works with FAISS, pgvector, TEI, LangChain, etc.
```

## Saving and deployment

```python
# LoRA-only (small, requires base model at load time)
model.save_pretrained("bge_m3_lora")
model.tokenizer.save_pretrained("bge_m3_lora")

# Merged 16-bit (portable)
model.save_pretrained_merged("bge_m3_16bit",
                             tokenizer=model.tokenizer,
                             save_method="merged_16bit")

# GGUF (handy for llama.cpp / Ollama embedding servers)
model.save_pretrained_gguf("bge_m3_gguf", quantization_method="q4_k_m")

# Push to Hub
model.push_to_hub("username/bge_m3_lora")
model.push_to_hub_merged("username/bge_m3_16bit",
                        tokenizer=model.tokenizer,
                        save_method="merged_16bit")
model.push_to_hub_gguf("username/bge_m3_gguf",
                      quantization_method=["q4_k_m", "q8_0", "f16"])
```

Serving:
- **Text Embeddings Inference (TEI)**: point `--model-id` at a merged HF path or the hub repo.
- **vLLM**: `vllm serve <path> --task embed` for supported architectures.
- **Custom**: plain `SentenceTransformer(...)` inside a FastAPI/Modal endpoint. Batch at the server boundary; normalize with `encode(..., normalize_embeddings=True)`.
- **Vector stores**: pgvector, FAISS, Weaviate, Qdrant, Chroma — all consume the resulting dense vectors directly.

## Rerankers / cross-encoders

Cross-encoders (e.g. `BAAI/bge-reranker-v2-m3`) are documented as working with Unsloth via the same `FastSentenceTransformer` fallback path; docs don't provide a verbatim recipe. Start from the embedding recipe above, swap in `losses.CrossEncoderLoss`-family from `sentence-transformers`, and use `{query, passage, label}` data.

## BERT-style classifier fine-tuning

Not an embedding task, but the encoder-side counterpart uses `FastModel` (not `FastSentenceTransformer`) because the head is different:

```python
from unsloth import FastModel
from transformers import AutoModelForSequenceClassification

model, tokenizer = FastModel.from_pretrained(
    model_name = "unsloth/ModernBERT-large",
    auto_model = AutoModelForSequenceClassification,
    max_seq_length = 2048,
    dtype = None,
    num_labels = 6,
    id2label = id2label,
    label2id = label2id,
    full_finetuning = True,                # often better than LoRA for classifiers
    load_in_4bit = False,
)

model = FastModel.get_peft_model(
    model,
    r = 16, lora_alpha = 16, lora_dropout = 0, bias = "none",
    target_modules = ["q_proj","k_proj","v_proj","o_proj",
                      "gate_proj","up_proj","down_proj"],
    use_gradient_checkpointing = "unsloth",
    task_type = "SEQ_CLS",                 # not FEATURE_EXTRACTION
)
```

Then train with `transformers.Trainer` + `TrainingArguments` on tokenized `{"text", "labels"}` data.

## Reference notebooks

- `EmbeddingGemma_(300M).ipynb`
- `Qwen3_Embedding_(0_6B).ipynb`, `Qwen3_Embedding_(4B).ipynb`
- `BGE_M3.ipynb`
- `All_MiniLM_L6_v2.ipynb`
- `bert_classification.ipynb` (ModernBERT classifier)

HF-side examples (`sbert.net/examples/sentence_transformer/training/unsloth/`):
- `training_gooaq_unsloth.py` — Cached MNRL with NanoBEIR evaluator, GooAQ QA retrieval.
- `training_medical_unsloth.py` — EmbeddingGemma with `InformationRetrievalEvaluator` on medical corpora.

## Canonical hyperparameters by model

| Model | `r` | `lora_alpha` | `lr` | `max_seq_length` | `lr_scheduler` |
|-------|-----|--------------|------|------------------|----------------|
| all-MiniLM-L6-v2 | 64 | 128 | 2e-4 | 256 | linear |
| BGE-M3 | 32 | 64 | 3e-5 | 512 | constant_with_warmup |
| EmbeddingGemma-300M | 32 | 64 | 2e-5 | 1024 | constant_with_warmup |
| Qwen3-Embedding-0.6B/4B | 32 | 64 | 3e-5 | 512-2048 | constant_with_warmup |

Rule of thumb: larger base model → lower LR. Training loss for MNRL typically lands in 0.1-1.5 depending on dataset difficulty.
