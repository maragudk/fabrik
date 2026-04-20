# Troubleshooting

## Environment flags

Set these **before** `from unsloth import ...` (they're read at import time):

| Flag | Effect |
|------|--------|
| `UNSLOTH_VLLM_STANDBY=1` | +30% context for RL; shares VRAM between vLLM generation and training phases. |
| `UNSLOTH_RETURN_LOGITS=1` | Forces logits return (useful for custom evaluators). |
| `UNSLOTH_COMPILE_DISABLE=1` | Disables `torch.compile` autopatch. Try when you hit obscure compile errors. |
| `UNSLOTH_DISABLE_FAST_GENERATION=1` | Disables fast generation fallback. Try on unusual/new models. |
| `UNSLOTH_ENABLE_LOGGING=1` | Emits compile logs. |
| `UNSLOTH_FORCE_FLOAT32=1` | Forces fp32 on fp16-only hardware. Gemma 3 workaround. |
| `UNSLOTH_STUDIO_DISABLED=1` | Turns off Studio extras. |
| `UNSLOTH_COMPILE_DEBUG=1` | Verbose compile debug output. |
| `UNSLOTH_COMPILE_MAXIMUM=0` | Aggressive compile optimizations. Not recommended. |
| `UNSLOTH_COMPILE_IGNORE_ERRORS=1` | Toggles fullgraph parsing behavior. |
| `UNSLOTH_FULLGRAPH=0` | Opt out of fullgraph `torch.compile` mode. |
| `UNSLOTH_DISABLE_AUTO_UPDATES=1` | Freezes `unsloth-zoo` at current version (avoids surprise upgrades). |
| `UNSLOTH_STABLE_DOWNLOADS=1` | Synchronous HF downloads. Fix for stalls at 90-95%. |

Classic CUDA-error rescue combo:

```bash
export UNSLOTH_COMPILE_DISABLE=1
export UNSLOTH_DISABLE_FAST_GENERATION=1
```

## Common failure modes

### `loss = 0.0` and stays there

`instruction_part` / `response_part` strings in `train_on_responses_only` don't match the model's chat template. All tokens get labeled `-100`, so there's nothing to compute loss on. Debug:

```python
row = trainer.train_dataset[0]
labels = row["labels"]
if all(l == -100 for l in labels):
    print("All labels are -100 — response-only masking strings are wrong.")
```

Verify the exact strings against the tokenizer:

```python
print(tokenizer.apply_chat_template(
    [{"role": "user", "content": "hi"}, {"role": "assistant", "content": "hello"}],
    tokenize=False))
```

Match `instruction_part` and `response_part` to the delimiters you see. Family-specific strings are in `sft.md`.

### Gibberish or infinite repetition after GGUF export

Three usual suspects, in order of likelihood:

1. Chat template wasn't set during training (`get_chat_template` skipped).
2. Client adds an extra BOS on top of one the template already emits → double-BOS.
3. Wrong stop tokens in the Modelfile (Ollama) or in the client's generate call.

Verify what the training tokenizer produced:

```python
print(tokenizer.apply_chat_template(messages, tokenize=True))
```

Then confirm the serving client produces the same token sequence.

### Wrong/untransformed embedding vectors

Missing `for_inference=True` on `FastSentenceTransformer.from_pretrained`. Without it, the Unsloth-patched forward pass doesn't apply the inference-time transformations and the output vectors are wrong — silently.

```python
model = FastSentenceTransformer.from_pretrained(path, for_inference=True)
```

### `OutOfMemoryError` during training

In order of escalating impact:

1. `per_device_train_batch_size = 1`, raise `gradient_accumulation_steps`.
2. Drop `max_seq_length`.
3. Lower `r` (LoRA rank).
4. Confirm `use_gradient_checkpointing = "unsloth"` (the string, not `True`).
5. Switch from LoRA 16-bit to QLoRA 4-bit (`load_in_4bit=True`).

### `OutOfMemoryError` during eval

```python
args = SFTConfig(
    ...,
    fp16_full_eval = True,
    per_device_eval_batch_size = 2,
    eval_accumulation_steps = 4,
)
```

### `OutOfMemoryError` during save

Lower `maximum_memory_usage` on the save call (default 0.75):

```python
model.save_pretrained_merged(path, tokenizer, save_method="merged_16bit",
                             maximum_memory_usage=0.5)
```

### `CUDA device-side assert triggered`

Try the rescue combo:

```bash
export UNSLOTH_COMPILE_DISABLE=1
export UNSLOTH_DISABLE_FAST_GENERATION=1
```

If that doesn't clear it, the input likely contains out-of-vocab token IDs (custom tokenizer added new tokens without `resize_token_embeddings`) or a mismatched `max_seq_length`.

### `Some weights of X were not initialized from the model checkpoint`

Upgrade the stack:

```bash
pip install -U unsloth unsloth_zoo transformers timm
```

If it persists, hit the force-reinstall escape hatch:

```bash
pip install --upgrade --force-reinstall --no-cache-dir --no-deps unsloth unsloth_zoo
```

### Colab `NotImplementedError: A UTF-8 locale is required`

```python
import locale
locale.getpreferredencoding = lambda: "UTF-8"
```

at the very top of the notebook, before any other import.

### First 5 minutes are slow

`torch.compile` warm-up. Measure throughput after it settles. Kick off a tiny forward pass before the training loop if you need consistent wall-clock timing from step 1.

### HF downloads stall at 90-95%

```bash
export UNSLOTH_STABLE_DOWNLOADS=1
```

Forces synchronous downloads instead of the async/chunked path that sometimes hangs near the end.

### Q8_K_XL feels slower than Q8_0 on Mac

Q8_K_XL upcasts layers to BF16, which is slower than BF16-native or Q8_0 on Apple silicon. Use Q8_0 for Macs.

### bitsandbytes / xformers / triton issues

Unsloth's recommended fallbacks:

1. Use the Docker image `unsloth/unsloth`. Avoids the whole toolchain.
2. Force-reinstall Unsloth (the escape hatch above).
3. Pin `xformers` to match your `torch` version:

| torch | xformers |
|-------|----------|
| 2.10  | 0.0.34 |
| 2.9   | 0.0.33.post1 |
| 2.8   | 0.0.32.post2 |

### "Model not supported"

Try `trust_remote_code=True`. For architectures that need custom attention kernels, add `unsloth_force_compile=True`:

```python
model, tokenizer = FastModel.from_pretrained(
    "org/weird-model",
    trust_remote_code = True,
    unsloth_force_compile = True,
    auto_model = AutoModel,
)
```

If that doesn't work, the model probably isn't Unsloth-compatible yet. Check the Unsloth GitHub issues; the team ships support quickly when a model trends.

### Gemma 3 on fp16-only hardware

Gemma 3 runs in bf16 by default. On fp16-only cards (T4, V100 older revisions):

```bash
export UNSLOTH_FORCE_FLOAT32=1
```

## Dep-hell escape hatch

One-line reinstall that usually unsticks weird package resolution states:

```bash
pip install --upgrade --force-reinstall --no-cache-dir --no-deps unsloth unsloth_zoo
```

If even that fails, use the Docker image:

```bash
docker run --gpus all -it --rm unsloth/unsloth
```

## When to file a bug

If you hit something that looks like a genuine Unsloth bug (not a config issue), their GitHub is active: https://github.com/unslothai/unsloth. A useful bug report includes:

- Output of `pip show unsloth unsloth_zoo transformers trl torch`.
- GPU model and CUDA version (`nvidia-smi`).
- A minimal 20-line script that reproduces it.
- The full traceback with any environment flags you had set.

The team often ships fixes within days for reproducible issues on common models.
