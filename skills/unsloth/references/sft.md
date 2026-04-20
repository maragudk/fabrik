# Supervised fine-tuning (SFT)

Unsloth's most common use: LoRA or QLoRA fine-tuning of decoder-only LLMs via TRL's `SFTTrainer`. The full end-to-end template is in SKILL.md; this file covers the knobs and edge cases that aren't on the golden path.

## Chat templates per family

`unsloth.chat_templates.get_chat_template(tokenizer, chat_template=NAME)` swaps the template onto the tokenizer. Valid names:

`zephyr`, `chatml`, `mistral`, `llama`, `llama-3`, `llama-3.1`, `alpaca`, `vicuna`, `vicuna_old`, `unsloth`, `phi-3`, `phi-4`, `gemma`, `gemma-3`, `qwen-2.5`

Enumerate at runtime:

```python
from unsloth.chat_templates import CHAT_TEMPLATES
print(list(CHAT_TEMPLATES.keys()))
```

## `train_on_responses_only` strings per family

Applies response-only masking: loss is computed only on assistant tokens. Boosts accuracy by roughly 1% on most SFT tasks. The strings must match the chat template exactly — a mismatch silently masks *all* tokens, producing `loss = 0.0`.

```python
from unsloth.chat_templates import train_on_responses_only

# Llama 3.1 / 3.2 / 3.3
trainer = train_on_responses_only(
    trainer,
    instruction_part = "<|start_header_id|>user<|end_header_id|>\n\n",
    response_part    = "<|start_header_id|>assistant<|end_header_id|>\n\n",
)

# Gemma 2 / 3 / 3n
trainer = train_on_responses_only(
    trainer,
    instruction_part = "<start_of_turn>user\n",
    response_part    = "<start_of_turn>model\n",
)

# Qwen 2.5 (ChatML-style)
trainer = train_on_responses_only(
    trainer,
    instruction_part = "<|im_start|>user\n",
    response_part    = "<|im_start|>assistant\n",
)

# Phi-3
trainer = train_on_responses_only(
    trainer,
    instruction_part = "<|user|>\n",
    response_part    = "<|assistant|>\n",
)
```

Sanity-check by printing `trainer.train_dataset[0]["labels"]` — if every label is `-100`, the strings are wrong.

## Dataset shapes and conversion

**Raw corpus (continued pretraining):**
```python
{"text": "arbitrary long-form text ..."}
```

**Alpaca (instruction tuning):**
```python
{"instruction": "...", "input": "...", "output": "..."}
```

Format it:

```python
alpaca_prompt = """Below is an instruction that describes a task, paired with an input that provides further context. Write a response that appropriately completes the request.

### Instruction:
{}

### Input:
{}

### Response:
{}"""

EOS = tokenizer.eos_token
def format(examples):
    texts = [alpaca_prompt.format(i, x, o) + EOS
             for i, x, o in zip(examples["instruction"],
                                examples["input"],
                                examples["output"])]
    return {"text": texts}
```

**ShareGPT (multi-turn):**
```python
{"conversations": [
    {"from": "human", "value": "..."},
    {"from": "gpt",   "value": "..."},
]}
```

Convert to ChatML:

```python
from unsloth.chat_templates import standardize_sharegpt
ds = standardize_sharegpt(ds)  # renames from/value -> role/content
```

**ChatML / messages:**
```python
{"messages": [
    {"role": "user",      "content": "..."},
    {"role": "assistant", "content": "..."},
]}
```

## Merging columns into conversations

`to_sharegpt` supports column templating (useful for custom datasets):

```python
from unsloth.chat_templates import to_sharegpt
ds = to_sharegpt(
    ds,
    merged_prompt = "[[Context: {context}\n\n]]Question: {question}",
    conversation_extension = 3,    # merge N rows into one multi-turn example
    output_column_name = "answer",
)
```

`[[optional]]` blocks are dropped if any `{col}` inside them is empty.

## Dataset size rule of thumb

- Minimum 100 rows to get a signal.
- Recommended 1,000+ for anything meant for production.
- Quality beats quantity: a few hundred high-quality examples beat 100k noisy ones.
- When starved: use a strong teacher (Llama-3.3-70B, GPT-4.x, Claude) to generate rewrites or additional examples, or use Unsloth's "Data Recipes" patterns.

## Continued pretraining

Different from SFT in three ways: train the token and position embeddings too, use a smaller LR for them, and use Unsloth's trainer wrappers.

```python
model = FastLanguageModel.get_peft_model(
    model,
    r = 16, lora_alpha = 16,
    target_modules = ["q_proj","k_proj","v_proj","o_proj",
                      "gate_proj","up_proj","down_proj",
                      "lm_head", "embed_tokens"],          # <-- extra
    use_gradient_checkpointing = "unsloth",
    random_state = 3407,
)

from unsloth import UnslothTrainer, UnslothTrainingArguments
trainer = UnslothTrainer(
    model = model,
    tokenizer = tokenizer,
    train_dataset = ds,
    dataset_text_field = "text",
    max_seq_length = 2048,
    args = UnslothTrainingArguments(
        per_device_train_batch_size = 2,
        gradient_accumulation_steps = 4,
        warmup_ratio = 0.1,
        num_train_epochs = 1,
        learning_rate = 5e-5,                # standard LR
        embedding_learning_rate = 5e-6,      # 10x smaller for embeddings + lm_head
        optim = "adamw_8bit",
        weight_decay = 0.01,
        lr_scheduler_type = "linear",
        seed = 3407,
        output_dir = "outputs",
    ),
)
```

## Resuming from a saved LoRA

```python
model, tokenizer = FastLanguageModel.from_pretrained(
    model_name = "path_to_lora_or_hub_repo",
    max_seq_length = 2048,
    load_in_4bit = True,
)
model = FastLanguageModel.get_peft_model(model, ...)
```

Caveat: the optimizer state is not preserved — resuming is a fresh optimizer on top of the adapter weights. For exact resume use HF Trainer's `resume_from_checkpoint=...` with a full checkpoint dir (not just the LoRA adapter).

## Packing and max_seq_length

`packing=True` in `SFTTrainer` concatenates short examples up to `max_seq_length`, improving throughput. Off by default because it changes training dynamics (different examples attend to each other across packed boundaries unless you use a packing-aware attention mask). Safe for short conversational data; not always for instruction tuning where order matters.

## Early stopping

```python
from transformers import EarlyStoppingCallback
trainer.add_callback(EarlyStoppingCallback(
    early_stopping_patience = 3,
    early_stopping_threshold = 0.0,
))

# SFTConfig must enable:
#   save_strategy          = "steps"
#   save_steps             = 10
#   save_total_limit       = 3
#   eval_strategy          = "steps"
#   eval_steps             = 10
#   load_best_model_at_end = True
#   metric_for_best_model  = "eval_loss"
#   greater_is_better      = False
```

## Multi-GPU

Unsloth works with `accelerate launch train.py` or `torchrun --nproc_per_node=N train.py` for DDP/FSDP today. Multi-GPU is flagged as "forthcoming enhancements" — expect rougher edges than single-GPU.

For large base models that exceed one GPU's VRAM, pass `device_map="balanced"` to `FastLanguageModel.from_pretrained` to spread layers across GPUs (e.g. a 70B 4-bit across 2x24GB cards).

## VRAM budgeting

Absolute minima (can train, barely):

| Model | QLoRA 4-bit | LoRA 16-bit |
|-------|-------------|-------------|
| 7B    | ~5 GB       | ~19 GB      |
| 8B    | ~6 GB       | ~22 GB      |
| 13B   | ~9 GB       | ~34 GB      |
| 33B   | ~20 GB      | ~78 GB      |
| 70B   | ~41 GB      | ~164 GB     |

OOM mitigations, in order:
1. `per_device_train_batch_size = 1`, raise `gradient_accumulation_steps`.
2. `max_seq_length` down (2048 → 1024 → 512).
3. Lower `r` (32 → 16 → 8).
4. `use_gradient_checkpointing = "unsloth"` (already on by default in the golden path).
5. Drop to QLoRA if you were on LoRA 16-bit.

## Known bad patterns

- Using HF's default `get_peft_model` from `peft` after loading with `FastLanguageModel.from_pretrained`. Always use `FastLanguageModel.get_peft_model` — it applies Unsloth's kernels.
- Forgetting to call `FastLanguageModel.for_inference(model)` after training. Generation still works but runs 2x slower than it should.
- Setting `lora_dropout > 0`. Unsloth's kernels assume 0 and are only modestly tuned for nonzero values.
- `learning_rate = 2e-4` for DPO/GRPO. Preference/RL LR should be ~5e-6 (see `rl.md`).
