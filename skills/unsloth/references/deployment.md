# Saving, exporting, and serving

## Save targets, ranked by size and portability

| Target | Command | Size | Use when |
|--------|---------|------|----------|
| LoRA adapter | `save_pretrained` | ~50-200 MB | Cheapest; downstream loads base + adapter. Good for experiments. |
| Merged 16-bit | `save_pretrained_merged(..., "merged_16bit")` | Full bf16 | Portable fp16/bf16 weights. Works with any transformers-compatible tool. |
| Merged 4-bit | `save_pretrained_merged(..., "merged_4bit")` | ~25% of fp16 | Quantized deploy without GGUF. |
| GGUF | `save_pretrained_gguf(..., quantization_method=...)` | Varies | llama.cpp, Ollama, LM Studio. |

```python
# LoRA adapter only
model.save_pretrained("lora_out")
tokenizer.save_pretrained("lora_out")

# Merged 16-bit
model.save_pretrained_merged("model_16bit", tokenizer, save_method="merged_16bit")

# Merged 4-bit (bitsandbytes)
model.save_pretrained_merged("model_4bit", tokenizer, save_method="merged_4bit")

# GGUF, one quantization
model.save_pretrained_gguf("model_gguf", tokenizer, quantization_method="q4_k_m")

# GGUF, multiple quantizations in one call
model.save_pretrained_gguf("model_gguf", tokenizer,
                           quantization_method=["q4_k_m", "q8_0", "f16"])
```

### Push to Hugging Face Hub

```python
# One-time auth:  hf auth login
model.push_to_hub("username/repo")                               # LoRA
model.push_to_hub_merged("username/repo", tokenizer,
                        save_method="merged_16bit")
model.push_to_hub_gguf("username/repo", tokenizer,
                      quantization_method=["q4_k_m", "q8_0", "f16"])
```

If auth isn't already done, add `token="hf_..."` to each call.

### Save OOM fix

Saving large models can OOM even when training didn't. Lower `maximum_memory_usage` (default 0.75) on the save call:

```python
model.save_pretrained_merged("out_16bit", tokenizer,
                             save_method="merged_16bit",
                             maximum_memory_usage=0.5)
```

## GGUF quantization method reference

Full list accepted by `save_pretrained_gguf(..., quantization_method=...)`:

`not_quantized`, `fast_quantized`, `quantized`, `f32`, `f16`, `q8_0`, `q4_k_m`, `q5_k_m`, `q2_k`, `q3_k_l`, `q3_k_m`, `q3_k_s`, `q4_0`, `q4_1`, `q4_k_s`, `q4_k`, `q5_k`, `q5_0`, `q5_1`, `q5_k_s`, `q6_k`, `iq2_xxs`, `iq2_xs`, `iq3_xxs`, `q3_k_xs`

Practical choices:

- `q4_k_m` — general-purpose. ~4.5 bits/weight, small quality hit. Most recommended default.
- `q5_k_m` — better quality than `q4_k_m`, noticeably larger.
- `q8_0` — near-lossless. Run it if you have the disk/VRAM for it.
- `f16` — reference point for comparisons and for further downstream quantization.
- `iq2_xxs`, `iq2_xs`, `iq3_xxs` — extreme compression; use only when the size constraint is hard and you've verified quality holds.

On Apple silicon: `q8_K_XL` upcasts layers to BF16, which is slower than plain bf16 on Apple silicon. Use `q8_0` instead on Macs.

## Manual GGUF conversion (when auto fails)

Auto-conversion can fail on cutting-edge architectures before `llama.cpp` adds support. Fallback:

```bash
# 1. Save merged 16-bit first
python -c "model.save_pretrained_merged('merged', tokenizer, save_method='merged_16bit')"

# 2. Build llama.cpp
apt-get install -y pciutils build-essential cmake curl libcurl4-openssl-dev
git clone https://github.com/ggerganov/llama.cpp
cmake llama.cpp -B llama.cpp/build \
  -DBUILD_SHARED_LIBS=ON -DGGML_CUDA=ON -DLLAMA_CURL=ON
cmake --build llama.cpp/build --config Release -j --clean-first \
  --target llama-quantize llama-cli llama-gguf-split llama-mtmd-cli

# 3. Convert
python llama.cpp/convert_hf_to_gguf.py merged \
  --outfile model-F16.gguf \
  --outtype f16 \
  --split-max-size 50G

# 4. Quantize
./llama.cpp/build/bin/llama-quantize model-F16.gguf model-Q4_K_M.gguf q4_k_m
```

## Ollama

After `save_pretrained_gguf`, Unsloth writes a `Modelfile` that matches the training chat template:

```bash
ollama create my-model -f ./model_gguf/Modelfile
ollama run my-model
```

If outputs look wrong after `ollama run`, 95% of the time it's the chat template:

- The Modelfile's `TEMPLATE` doesn't match what the model was trained on.
- The `PARAMETER stop` values are missing or wrong.
- An extra BOS is being added by Ollama on top of the one the template already emits.

Fix by editing the Modelfile to match the training template (compare with `tokenizer.chat_template` from the training run) and re-running `ollama create`.

## vLLM

Serving merged weights:

```bash
uv pip install -U vllm --torch-backend=auto
vllm serve unsloth/gpt-oss-120b
# or a local merged path
vllm serve ./model_16bit
```

Training-time integration: setting `fast_inference=True` in `FastLanguageModel.from_pretrained` uses vLLM as the generation backend (used by GRPO). Relevant knobs:

- `max_lora_rank` — must match the rank you'll later use in `get_peft_model`.
- `gpu_memory_utilization` — 0.9-0.95 with `UNSLOTH_VLLM_STANDBY=1`, 0.5-0.7 without.

vLLM supports LoRA hot-swapping at serve time — you can serve one merged base and load/unload adapters per request. See unsloth.ai/docs/basics/inference-and-deployment/vllm-guide for specifics.

## SGLang, LM Studio, llama-server

All three consume GGUF. SGLang and LM Studio have first-party docs pages; `llama-server` (from llama.cpp) exposes an OpenAI-compatible endpoint out of the box:

```bash
./llama.cpp/build/bin/llama-server \
  --model model-Q4_K_M.gguf \
  --port 8080 \
  --host 0.0.0.0 \
  --ctx-size 4096
```

Then point any OpenAI SDK client at `http://localhost:8080/v1`.

## Phone / on-device

Unsloth has a dedicated docs page for mobile deployment via MLC, ExecuTorch, and others. The workflow is: train → merged 16-bit → convert with the target tool — Unsloth's surface ends at the merged weights.

## Embedding-model serving

See `embeddings.md`. Summary:

- Text Embeddings Inference (TEI): `text-embeddings-router --model-id <path-or-hub>`.
- vLLM: `vllm serve <path> --task embed` (supported architectures only).
- Plain `SentenceTransformer(...)` inside a FastAPI/Modal endpoint works for anything.
- Vector stores accept the dense vectors directly — no special driver.

## Modal deployment template

```python
import modal

VOLUME_CACHE = modal.Volume.from_name("hf-cache", create_if_missing=True)
VOLUME_OUT   = modal.Volume.from_name("unsloth-out", create_if_missing=True)

image = (
    modal.Image.debian_slim(python_version="3.11")
    .apt_install("git")
    # Import unsloth before transformers/peft/trl — pin exact versions.
    .uv_pip_install(
        "unsloth==2025.11.0",
        "unsloth_zoo==2025.11.0",
        "transformers==4.56.2",
        "trl==0.22.2",
        "peft",
        "datasets",
        "sentence-transformers",
    )
    .env({"HF_HOME": "/model_cache"})
)

app = modal.App("unsloth-train", image=image)

@app.function(
    gpu = "L40S",                 # or "H100", "A100-80GB"
    timeout = 6 * 60 * 60,
    volumes = {
        "/model_cache": VOLUME_CACHE,
        "/out":          VOLUME_OUT,
    },
    retries = modal.Retries(max_retries=3),
)
def train():
    import unsloth                 # MUST be first
    from unsloth import FastLanguageModel
    # ... rest of the training script
```

Tips:
- Pin exact Unsloth versions. Nightly-ish releases break reproducibility.
- Import `unsloth` before `transformers`, `peft`, or `trl`.
- Mount a Modal `Volume` at `HF_HOME=/model_cache` so weight downloads survive restarts. Separate volumes for data and checkpoints enable reuse.
- First image build takes 15-20 min (cached afterwards). First `.remote()` call after deploy has a 30-60s cold start.
- From a marimo notebook: call `.remote()` on the Modal function from a cell. Locally the notebook stays snappy; the GPU work runs on Modal.

## Post-export sanity test

Always run a quick inference smoke test after any export path before shipping:

```python
# Decoder LLM
from transformers import AutoModelForCausalLM, AutoTokenizer
m = AutoModelForCausalLM.from_pretrained("out_16bit", torch_dtype="auto", device_map="auto")
t = AutoTokenizer.from_pretrained("out_16bit")
out = m.generate(**t(["Hello"], return_tensors="pt").to("cuda"), max_new_tokens=32)
print(t.batch_decode(out))

# Embedding
from sentence_transformers import SentenceTransformer
m = SentenceTransformer("out_st_16bit")
print(m.encode(["test query", "test document"]))
```

If this produces garbage, the problem is almost always the chat template (LLMs) or `for_inference=True` was missing during training validation (embeddings).
