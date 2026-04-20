---
name: unsloth
description: Guide for fine-tuning LLMs, embedding models, vision-language models, and TTS models efficiently with Unsloth. Covers LoRA/QLoRA SFT, reinforcement learning (GRPO, DPO, ORPO, KTO), embedding fine-tuning with sentence-transformers, continued pretraining, and saving/exporting to GGUF, Ollama, or vLLM. Use this skill whenever the user mentions Unsloth, FastLanguageModel, FastSentenceTransformer, FastVisionModel, FastModel, or wants memory-efficient fine-tuning of open LLMs or embedding models on a single GPU, even if they don't explicitly say "Unsloth".
license: MIT
---

# unsloth

## Overview

Unsloth (https://unsloth.ai) is an open-source library that fine-tunes open LLMs ~2x faster with ~70% less VRAM than vanilla Hugging Face + Flash Attention 2, using hand-written Triton kernels for the QLoRA/LoRA forward and backward passes. It wraps around `transformers`, `peft`, and TRL's trainers (`SFTTrainer`, `GRPOTrainer`, `DPOTrainer`, `KTOTrainer`, `ORPOTrainer`) rather than replacing them — so existing HF code ports over easily.

Use this skill when:
- Fine-tuning any LLM on a single GPU (or two) and you care about speed or VRAM.
- Fine-tuning an embedding or reranker model (BGE-M3, EmbeddingGemma, Qwen3-Embedding, MiniLM, MPNet, ModernBERT).
- Doing RL on reasoning models (GRPO) or preference optimization (DPO/ORPO/KTO).
- Exporting a fine-tuned model to GGUF for Ollama/llama.cpp or to vLLM/SGLang for serving.

Do **not** reach for Unsloth when the workload demands first-class multi-GPU training; Unsloth works with `accelerate`/DeepSpeed but multi-GPU is still maturing. Axolotl or torchtune are better defaults there.

## The three load-bearing rules

These three show up in every Unsloth script and failing to follow them produces silent, hard-to-debug mistakes:

1. **Import `unsloth` first.** Before `transformers`, `peft`, `trl`, or `sentence_transformers`. Unsloth monkey-patches those libraries on import; the patches only apply to modules not yet imported.

2. **`use_gradient_checkpointing="unsloth"`** is a magic string, not a boolean. `True` gives you standard HF checkpointing. The string `"unsloth"` gives you Unsloth's implementation: ~30% less VRAM and ~2x larger batches. Always use the string.

3. **Reloading an embedding model for inference requires `for_inference=True`.** `FastSentenceTransformer.from_pretrained(path, for_inference=True)` — otherwise the model silently emits wrong (untransformed) vectors. This does not apply to decoder LMs (they use `FastLanguageModel.for_inference(model)` as a separate call).

## Installation

Pick one; they are listed in order of preference for fresh environments:

```bash
# 1. uv (fastest, recommended)
uv pip install unsloth --torch-backend=auto
# add vLLM when doing RL or fast inference:
uv pip install unsloth vllm --torch-backend=auto

# 2. plain pip
pip install unsloth

# 3. bleeding-edge main (when a fix hasn't shipped yet)
pip uninstall unsloth unsloth_zoo -y
pip install --no-deps git+https://github.com/unslothai/unsloth_zoo.git
pip install --no-deps git+https://github.com/unslothai/unsloth.git

# 4. dependency hell escape hatch
pip install --upgrade --force-reinstall --no-cache-dir --no-deps unsloth unsloth_zoo
```

Requirements: NVIDIA GPU with CUDA capability ≥7.0, CUDA 12.4+ (12.8+ for Blackwell), Python 3.11-3.13. AMD and Intel are supported via the "Unsloth Core" install pages; macOS/MLX is listed as coming soon. Pin `transformers` and `trl` to known-good versions — Unsloth ships frequently.

For Modal deployments, install inside the `modal.Image.uv_pip_install(...)` layer and pin exact versions, since nightly-ish releases can break reproducibility. See `references/deployment.md` for a full Modal example.

## The four APIs

| Class | Use for |
|-------|---------|
| `FastLanguageModel` | Standard decoder LLMs (Llama, Qwen, Mistral, Gemma, Phi, DeepSeek). The default. |
| `FastSentenceTransformer` | Encoder embedding and reranker models (BGE, EmbeddingGemma, Qwen3-Embedding, MiniLM, ModernBERT). |
| `FastVisionModel` | Multimodal VLMs (Llama-Vision, Qwen-VL, Pixtral, LLaVA, Gemma-3 vision). |
| `FastModel` | Generic loader for anything else: classification heads (`AutoModelForSequenceClassification`), TTS (Orpheus, Sesame-CSM, Spark-TTS), STT (Whisper), and models requiring `trust_remote_code=True`. |

All four share the same shape: `from_pretrained(...)`, `get_peft_model(...)`, and save/push helpers (`save_pretrained`, `save_pretrained_merged`, `save_pretrained_gguf`, `push_to_hub*`).

## Golden path: embedding fine-tuning

This is the flow for BGE-M3, EmbeddingGemma, Qwen3-Embedding, MiniLM, and similar. Embedding training uses Hugging Face's `SentenceTransformerTrainer`, not TRL's `SFTTrainer`.

```python
from unsloth import FastSentenceTransformer, is_bf16_supported

model = FastSentenceTransformer.from_pretrained(
    model_name = "unsloth/bge-m3",       # or embeddinggemma-300m, Qwen3-Embedding-0.6B, all-MiniLM-L6-v2
    max_seq_length = 512,                # 1024 for EmbeddingGemma; bump for long-context retrieval
    full_finetuning = False,             # True disables LoRA
)

model = FastSentenceTransformer.get_peft_model(
    model,
    r = 32,                              # MiniLM uses 64; BGE-M3 and Qwen3-Emb use 32
    lora_alpha = 64,                     # typically r or 2*r
    lora_dropout = 0,
    bias = "none",
    target_modules = ["key", "query", "value", "dense"],   # BERT/BGE family
    # target_modules = ["q_proj","k_proj","v_proj","o_proj","gate_proj","up_proj","down_proj"],  # EmbeddingGemma / Qwen3-Emb
    use_gradient_checkpointing = False,  # "unsloth" for EmbeddingGemma
    task_type = "FEATURE_EXTRACTION",    # crucial — not SEQ_CLS
    random_state = 3407,
)

from datasets import load_dataset
dataset = load_dataset("sentence-transformers/all-nli", "pair", split="train[:100000]")
# Each row: {"anchor": "...", "positive": "..."} — MNRL uses in-batch examples as negatives.

from sentence_transformers import (
    SentenceTransformerTrainer, SentenceTransformerTrainingArguments, losses,
)
from sentence_transformers.training_args import BatchSamplers

trainer = SentenceTransformerTrainer(
    model = model,
    train_dataset = dataset,
    loss = losses.MultipleNegativesRankingLoss(model),
    args = SentenceTransformerTrainingArguments(
        output_dir = "output",
        num_train_epochs = 2,
        per_device_train_batch_size = 256,       # large batches feed MNRL more in-batch negatives
        learning_rate = 3e-5,                    # 2e-4 MiniLM, 2e-5 EmbeddingGemma, 3e-5 BGE/Qwen3
        warmup_ratio = 0.03,
        lr_scheduler_type = "constant_with_warmup",
        bf16 = is_bf16_supported(),
        fp16 = not is_bf16_supported(),
        batch_sampler = BatchSamplers.NO_DUPLICATES,  # avoids in-batch duplicate false-negatives with MNRL
        logging_steps = 50,
        report_to = "none",
    ),
)
trainer.train()

# Reload for inference (remember for_inference=True!)
model = FastSentenceTransformer.from_pretrained("output", for_inference=True)
```

**Loss choice:**
- `MultipleNegativesRankingLoss` — default for `{anchor, positive}` pairs. Larger batches = harder negatives = better model.
- `CachedMultipleNegativesRankingLoss` — same idea but memory-efficient; use when batch size is VRAM-constrained.
- `TripletLoss` — for `{anchor, positive, negative}` triplets.

**Evaluation:** attach an `InformationRetrievalEvaluator` with `eval_strategy="steps"` + `eval_steps=N` in the training args. See `references/embeddings.md` for the full pattern.

**Deployment:** once saved (`save_pretrained` or `save_pretrained_merged`), production code can load with plain `SentenceTransformer(...)` — no Unsloth dependency needed downstream. Works with FAISS, pgvector, Weaviate, TEI, LangChain, LlamaIndex.

See `references/embeddings.md` for: classifier training on ModernBERT, reranker/cross-encoder training, the EmbeddingGemma query/document `prompts` pattern, and GGUF export for embedding servers.

## Golden path: causal LLM SFT (LoRA / QLoRA)

```python
from unsloth import FastLanguageModel

model, tokenizer = FastLanguageModel.from_pretrained(
    model_name = "unsloth/Llama-3.1-8B",
    max_seq_length = 2048,
    dtype = None,                    # auto: bf16 if supported, else fp16
    load_in_4bit = True,             # QLoRA
)

model = FastLanguageModel.get_peft_model(
    model,
    r = 16,                          # 8/16/32/64/128; 16 is the safe default
    lora_alpha = 16,                 # = r (or 2*r)
    lora_dropout = 0,                # Unsloth is optimized for 0
    bias = "none",
    target_modules = ["q_proj","k_proj","v_proj","o_proj",
                      "gate_proj","up_proj","down_proj"],
    use_gradient_checkpointing = "unsloth",
    random_state = 3407,
)

from unsloth.chat_templates import get_chat_template, standardize_sharegpt
tokenizer = get_chat_template(tokenizer, chat_template="llama-3.1")

from datasets import load_dataset
ds = load_dataset("mlabonne/FineTome-100k", split="train")
ds = standardize_sharegpt(ds)    # normalizes {from,value} -> {role,content}

def format(examples):
    texts = [tokenizer.apply_chat_template(c, tokenize=False, add_generation_prompt=False)
             for c in examples["conversations"]]
    return {"text": texts}
ds = ds.map(format, batched=True)

from trl import SFTTrainer, SFTConfig
trainer = SFTTrainer(
    model = model, tokenizer = tokenizer, train_dataset = ds,
    dataset_text_field = "text", max_seq_length = 2048, packing = False,
    args = SFTConfig(
        per_device_train_batch_size = 2,
        gradient_accumulation_steps = 4,
        warmup_steps = 5,
        max_steps = 60,              # or num_train_epochs = 1..3 for a full run
        learning_rate = 2e-4,
        optim = "adamw_8bit",
        weight_decay = 0.001,
        lr_scheduler_type = "linear",
        seed = 3407,
        output_dir = "outputs",
        logging_steps = 1,
        report_to = "none",
    ),
)

# Optional: train only on assistant tokens. Boosts accuracy ~1%.
# Watch out: wrong strings here silently produce all labels = -100 => loss = 0.
from unsloth.chat_templates import train_on_responses_only
trainer = train_on_responses_only(
    trainer,
    instruction_part = "<|start_header_id|>user<|end_header_id|>\n\n",
    response_part    = "<|start_header_id|>assistant<|end_header_id|>\n\n",
)

trainer.train()

FastLanguageModel.for_inference(model)    # switch to fast inference mode
```

See `references/sft.md` for: chat template strings per family (Llama, Gemma, Qwen, Phi), dataset formats (Alpaca, ShareGPT, ChatML, raw text), continued pretraining with `UnslothTrainer`, multi-GPU notes, and early stopping.

## Golden path: RL (GRPO, DPO, and friends)

GRPO is Unsloth's flagship RL pathway for training reasoning models with verifiable rewards (math, code execution, schema validation). DPO/ORPO/KTO/SimPO are supported via TRL trainers; PPO is supported but less documented.

GRPO preconditions: model ≥1.5B params, dataset ≥500 rows, train for ≥300 steps before expecting reward curves to improve.

```python
import os
os.environ["UNSLOTH_VLLM_STANDBY"] = "1"   # +30% context, shares mem with vLLM

from unsloth import FastLanguageModel
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name = "meta-llama/Llama-3.2-3B-Instruct",
    max_seq_length = 2048,
    load_in_4bit = False,           # 16-bit LoRA for RL
    fast_inference = True,          # vLLM generation backend
    max_lora_rank = 64,
    gpu_memory_utilization = 0.9,
)

model = FastLanguageModel.get_peft_model(
    model,
    r = 64, lora_alpha = 64, lora_dropout = 0, bias = "none",
    target_modules = ["q_proj","k_proj","v_proj","o_proj",
                      "gate_proj","up_proj","down_proj"],
    use_gradient_checkpointing = "unsloth",
    random_state = 3407,
)

from trl import GRPOConfig, GRPOTrainer
trainer = GRPOTrainer(
    model = model, tokenizer = tokenizer,
    reward_funcs = [match_format_exactly, check_answer, check_numbers],  # your verifiers
    train_dataset = dataset,
    args = GRPOConfig(
        learning_rate = 5e-6,           # RL LR: ~40x smaller than SFT
        weight_decay = 0.1,
        warmup_ratio = 0.1,
        lr_scheduler_type = "cosine",
        optim = "adamw_8bit",
        per_device_train_batch_size = 1,
        gradient_accumulation_steps = 4,
        num_generations = 4,            # 4-8 typical; lower if OOM
        max_prompt_length = 512,
        max_completion_length = 1536,
        max_steps = 500,
        save_steps = 250,
        report_to = "none",
        output_dir = "outputs",
    ),
)
trainer.train()
```

**Reward-function signatures:** `fn(completions, **kwargs) -> list[float]` or `fn(prompts, completions, answer, **kwargs) -> list[float]`. Prefer many small verifiers over one monolithic score — each one becomes a separate learning signal.

**DPO quirk:** call `PatchDPOTrainer()` before constructing the trainer. DPO can run with `ref_model=None` under Unsloth.

See `references/rl.md` for: reward design patterns, DPO/ORPO/KTO recipes, the `loss_type` / `epsilon` knobs that unlock DAPO and GSPO variants, and memory-efficient RL with `UNSLOTH_VLLM_STANDBY`.

## Golden path: vision fine-tuning

```python
from unsloth import FastVisionModel
model, tokenizer = FastVisionModel.from_pretrained(
    "unsloth/Llama-3.2-11B-Vision-Instruct",
    load_in_4bit = True,
    use_gradient_checkpointing = "unsloth",
)
model = FastVisionModel.get_peft_model(
    model,
    finetune_vision_layers = True,
    finetune_language_layers = True,
    finetune_attention_modules = True,
    finetune_mlp_modules = True,
    r = 16, lora_alpha = 16, lora_dropout = 0,
    bias = "none", random_state = 3407,
)
```

Use `UnslothVisionDataCollator`. Keep images in the 300-1000px range. For multi-image datasets, use list comprehensions rather than `dataset.map()` (documented pitfall).

See `references/vision-and-tts.md` for: conversation shape, the supported VLM/TTS catalog, Whisper STT, and Orpheus/Sesame-CSM TTS training.

## Chat templates and dataset formats

Four canonical dataset shapes:

1. **Raw text** (continued pretraining): `{"text": "..."}`
2. **Alpaca**: `{"instruction": "...", "input": "...", "output": "..."}`
3. **ShareGPT multi-turn**: `{"conversations": [{"from": "human", "value": "..."}, ...]}`
4. **ChatML messages**: `{"messages": [{"role": "user", "content": "..."}, ...]}`

`standardize_sharegpt(ds)` normalizes (3) into (4). `get_chat_template(tokenizer, chat_template="...")` swaps in the right template; accepted names include `llama-3.1`, `llama-3`, `chatml`, `mistral`, `gemma`, `gemma-3`, `qwen-2.5`, `phi-3`, `phi-4`, `alpaca`, `vicuna`, `zephyr`, `unsloth`.

Dataset-size heuristic: absolute minimum ~100 rows, recommended 1,000+. Quality beats quantity. Use synthetic augmentation (e.g. a strong teacher model generating rewrites) when starved for data.

## Recommended hyperparameters

Start here; tune only if the defaults misbehave.

| Parameter | SFT | RL (GRPO/DPO) | Continued pretrain |
|-----------|-----|---------------|---------------------|
| `learning_rate` | 2e-4 | 5e-6 | 5e-5 (+ `embedding_learning_rate=5e-6` for `lm_head`/`embed_tokens`) |
| `num_train_epochs` | 1-3 | n/a (use `max_steps`) | 1-2 |
| `r` (LoRA rank) | 16 or 32 | 64 | 16 |
| `lora_alpha` | `r` or `2*r` | `r` | `r` |
| `lora_dropout` | 0 | 0 | 0 |
| `weight_decay` | 0.001-0.01 | 0.1 | 0.001-0.01 |
| `per_device_train_batch_size` | 2 | 1 | 2 |
| `gradient_accumulation_steps` | 4 | 4 | 4 |
| `warmup_steps` / `warmup_ratio` | 5 steps | 0.1 ratio | 0.03-0.1 ratio |
| `lr_scheduler_type` | `linear` | `cosine` | `linear` |
| `optim` | `adamw_8bit` | `adamw_8bit` | `adamw_8bit` |
| `seed` / `random_state` | 3407 | 3407 | 3407 |

Target modules: `["q_proj","k_proj","v_proj","o_proj","gate_proj","up_proj","down_proj"]` (all linear) for most architectures; add `"lm_head"` and `"embed_tokens"` for continued pretraining. BERT-family embedding models use `["key","query","value","dense"]` instead.

Healthy training loss lands in 0.5-1.0. If overfitting: lower LR, fewer epochs, higher weight decay, scale alpha 0.5× post-train. If underfitting: more epochs, higher rank/alpha, better data.

## Saving and deployment

Three save targets. Pick based on downstream consumer.

```python
# LoRA adapters only (~100MB, cheapest; merge later)
model.save_pretrained("out_lora"); tokenizer.save_pretrained("out_lora")

# Merged weights (portable, works anywhere transformers does)
model.save_pretrained_merged("out_16bit", tokenizer, save_method="merged_16bit")

# GGUF for llama.cpp / Ollama
model.save_pretrained_gguf("out_gguf", tokenizer, quantization_method="q4_k_m")

# Push to HF Hub
model.push_to_hub("username/name")
model.push_to_hub_merged("username/name", tokenizer, save_method="merged_16bit")
model.push_to_hub_gguf("username/name", tokenizer,
                       quantization_method=["q4_k_m","q8_0","f16"])
```

Recommended GGUF quantizations: `q4_k_m` (general), `q8_0` (faster, nearly lossless), `f16` (reference). Unsloth auto-generates a matching `Modelfile` so `ollama create` works without surgery.

If the model fails to export silently or inference looks broken, 95% of the time it's either (a) the wrong chat template at inference, or (b) an extra BOS token on the client side. See `references/troubleshooting.md`.

See `references/deployment.md` for: merged 4-bit export, vLLM/SGLang serving, LM Studio, manual GGUF conversion via llama.cpp when auto fails, and the Modal integration recipe.

## Troubleshooting quick reference

Most common failure modes:

- **Loss is exactly 0** → `instruction_part`/`response_part` strings don't match the model's chat template; all labels masked to -100.
- **Gibberish after GGUF export** → wrong chat template or double-BOS at inference time.
- **CUDA device-side assert** → set `UNSLOTH_COMPILE_DISABLE=1` and `UNSLOTH_DISABLE_FAST_GENERATION=1` before importing `unsloth`.
- **OOM during eval** → set `fp16_full_eval=True`, `per_device_eval_batch_size=2`, `eval_accumulation_steps=4`.
- **OOM during save** → lower `maximum_memory_usage` (default 0.75, try 0.5) on the save call.
- **HF download stalls at 90-95%** → `UNSLOTH_STABLE_DOWNLOADS=1`.
- **"Not initialized from model checkpoint" warnings** → upgrade `unsloth`, `unsloth_zoo`, `transformers`, `timm`.
- **First 5 min feel slow** → `torch.compile` warm-up. Measure after it settles.

See `references/troubleshooting.md` for the full environment-flag reference and the rarer failure modes (Gemma 3 on fp16 hardware, bitsandbytes/xformers version mismatches, Colab locale fix).

## Model naming conventions

Repos at `unsloth/<family>-<size>-<variant>-<quant>`:

- `-bnb-4bit` — community bitsandbytes 4-bit quant.
- `-unsloth-bnb-4bit` — Unsloth's tuned 4-bit (dynamic-2.0).
- `-GGUF` — pre-made GGUF at various quants.
- `-Instruct-...` vs base.

When in doubt, prefer the `unsloth/...` mirror over the original upstream — Unsloth pre-applies fixes for tokenizer/template bugs and ships the 4-bit variant.

## References

Detailed material in `references/`:

- `embeddings.md` — full embedding recipe variants (BGE, EmbeddingGemma, Qwen3, MiniLM, ModernBERT classifier, rerankers), evaluators, deployment to TEI/vLLM/pgvector.
- `sft.md` — LoRA/QLoRA SFT deep dive: chat templates per family, `train_on_responses_only` strings, continued pretraining, early stopping.
- `rl.md` — GRPO reward design, DPO/ORPO/KTO, `UNSLOTH_VLLM_STANDBY`, long-context RL, FP8 RL.
- `vision-and-tts.md` — VLMs (Llama-Vision, Qwen-VL, Pixtral, LLaVA, Gemma-3), TTS (Orpheus, Sesame-CSM, Spark-TTS), Whisper STT, OCR models.
- `deployment.md` — merged export, GGUF, Ollama, vLLM, SGLang, LM Studio, manual llama.cpp conversion, Modal example.
- `troubleshooting.md` — full environment flag reference, common errors, dep-hell escape hatches.

Canonical external resources:

- Docs: https://unsloth.ai/docs
- Notebooks: https://github.com/unslothai/notebooks
- HF org: https://huggingface.co/unsloth
