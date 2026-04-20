# Vision and TTS fine-tuning

## Vision-language models (VLMs)

`FastVisionModel` wraps multimodal decoders that accept image + text input.

### Supported models (bnb-4bit ready)

- Llama-3.2-Vision (11B, 90B)
- Pixtral-12B
- Qwen2-VL (2B, 7B, 72B), Qwen2.5-VL, Qwen3-VL
- LLaVA 1.5, LLaVA 1.6
- Gemma-3 4B vision
- Ministral 3
- DeepSeek-OCR (needs `trust_remote_code=True`, `unsloth_force_compile=True`, `auto_model=AutoModel`)

### Load + PEFT

```python
from unsloth import FastVisionModel

model, tokenizer = FastVisionModel.from_pretrained(
    "unsloth/Llama-3.2-11B-Vision-Instruct",
    load_in_4bit = True,
    use_gradient_checkpointing = "unsloth",
)

model = FastVisionModel.get_peft_model(
    model,
    finetune_vision_layers     = True,
    finetune_language_layers   = True,
    finetune_attention_modules = True,
    finetune_mlp_modules       = True,
    r = 16, lora_alpha = 16, lora_dropout = 0,
    bias = "none", random_state = 3407,
    use_rslora = False, loftq_config = None,
)
```

The four `finetune_*` booleans control which parts of the network get LoRA adapters. Start with all four on; turn off vision layers if you only want to teach new tasks on existing visual features, or turn off language layers to specialize the vision encoder.

### Conversation shape

```python
[
    {"role": "user", "content": [
        {"type": "text",  "text": "What does this chart show?"},
        {"type": "image", "image": pil_image_or_path},
    ]},
    {"role": "assistant", "content": [
        {"type": "text", "text": "The chart shows ..."},
    ]},
]
```

### Data collator

`UnslothVisionDataCollator` is the supported path. It handles image resizing (`min`, `max`, or custom dims), response-only masking, and padding. Configure image size at collator construction, not per-sample.

```python
from unsloth.trainer import UnslothVisionDataCollator

collator = UnslothVisionDataCollator(
    model = model,
    tokenizer = tokenizer,
    resize = "min",              # "min" | "max" | (width, height)
)
```

### Training loop

Standard TRL `SFTTrainer` with the vision collator:

```python
from trl import SFTTrainer, SFTConfig

trainer = SFTTrainer(
    model = model,
    tokenizer = tokenizer,
    data_collator = collator,
    train_dataset = dataset,      # list/Dataset of conversations in the shape above
    args = SFTConfig(
        per_device_train_batch_size = 1,
        gradient_accumulation_steps = 4,
        warmup_steps = 5,
        max_steps = 30,
        learning_rate = 2e-4,
        optim = "adamw_8bit",
        weight_decay = 0.01,
        lr_scheduler_type = "linear",
        seed = 3407,
        output_dir = "outputs",
        remove_unused_columns = False,   # REQUIRED with the vision collator
        dataset_text_field = "",
        dataset_kwargs = {"skip_prepare_dataset": True},
        max_seq_length = 2048,
    ),
)

FastVisionModel.for_training(model)      # enable gradients on all trainable params
trainer.train()
```

### Vision gotchas

- Image sizes: 300-1000px is the documented sweet spot. Larger images eat more VRAM and rarely improve quality.
- **Multi-image datasets: use list comprehensions, not `dataset.map()`.** Documented pitfall — `dataset.map` mishandles nested image lists.
- `remove_unused_columns = False` on `SFTConfig` is mandatory when using the vision collator.
- For inference, use `FastVisionModel.for_inference(model)` — same pattern as decoder LMs.

### Inference

```python
FastVisionModel.for_inference(model)

messages = [
    {"role": "user", "content": [
        {"type": "text",  "text": "Caption this."},
        {"type": "image", "image": image},
    ]},
]
inputs = tokenizer.apply_chat_template(
    messages, add_generation_prompt=True,
    tokenize=True, return_tensors="pt", return_dict=True,
).to("cuda")

from transformers import TextStreamer
streamer = TextStreamer(tokenizer, skip_prompt=True)
_ = model.generate(**inputs, streamer=streamer, max_new_tokens=256,
                   temperature=0.7, top_p=0.9)
```

## Text-to-speech (TTS)

`FastModel` handles the TTS families (not `FastLanguageModel`). Supported:

- Sesame-CSM 1B
- Orpheus-TTS 3B
- Spark-TTS 0.5B
- Llasa-TTS 1B
- Oute-TTS 1B

Any transformers-compatible TTS model will likely work — these are just the tested ones.

### Load

```python
from unsloth import FastModel

model, tokenizer = FastModel.from_pretrained(
    "unsloth/orpheus-3b-0.1-pretrained",
    load_in_4bit = False,     # TTS models are small; QLoRA less relevant
)
```

### Dataset prep

Use the HF `Audio` feature and cast to the model's expected sampling rate (24000 for Orpheus):

```python
from datasets import load_dataset, Audio

ds = load_dataset("your/voice-dataset", split="train")
ds = ds.cast_column("audio", Audio(sampling_rate=24000))
```

Emotion tags (where supported) go inline in the text — e.g. Orpheus accepts `<laugh>`, `<sigh>`, `<cough>`, `<yawn>`, `<gasp>`.

### Training

Plain `transformers.Trainer` with `TrainingArguments`, not TRL's `SFTTrainer`:

```python
from transformers import Trainer, TrainingArguments

trainer = Trainer(
    model = model,
    tokenizer = tokenizer,
    train_dataset = ds,
    args = TrainingArguments(
        per_device_train_batch_size = 1,
        gradient_accumulation_steps = 4,
        warmup_steps = 5,
        max_steps = 60,
        learning_rate = 2e-4,
        optim = "adamw_8bit",
        weight_decay = 0.01,
        lr_scheduler_type = "linear",
        seed = 3407,
        output_dir = "tts_out",
        report_to = "none",
    ),
)
trainer.train()
```

Orpheus and Sesame-CSM notebooks are the reference implementations.

## Whisper (STT)

Whisper-Large-v3 is supported through `FastModel`. The training pattern is the HF `Seq2SeqTrainer` with a standard audio + transcript dataset — Unsloth provides the fast kernels, the training loop follows HF's official Whisper fine-tuning docs.

## OCR models

DeepSeek-OCR (and similar) load through `FastModel` with `trust_remote_code=True`:

```python
from unsloth import FastModel
from transformers import AutoModel

model, tokenizer = FastModel.from_pretrained(
    "deepseek-ai/DeepSeek-OCR",
    auto_model = AutoModel,
    trust_remote_code = True,
    unsloth_force_compile = True,
    load_in_4bit = False,
)
```

The same pattern applies to other models whose Hugging Face repos include custom code.
