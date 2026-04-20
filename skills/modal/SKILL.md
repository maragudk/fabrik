---
name: modal
description: Guide for running Python code on Modal, the serverless compute platform for AI workloads, batch jobs, scheduled tasks, web endpoints, and sandboxed code execution. Use this skill whenever the user is writing or modifying Modal code (anything importing `modal`, decorating with `@app.function`, `@app.cls`, `@modal.fastapi_endpoint`, etc.), running `modal run`/`modal deploy`/`modal serve`, configuring GPUs/images/volumes/secrets for Modal, or asking how to host inference, fine-tuning, or agent sandboxes on Modal.
license: MIT
---

# Modal

## Overview

Modal is a serverless Python compute platform. You define container images, functions, and resources in Python, then run them remotely with sub-second cold starts and per-second billing. There is no YAML, no Dockerfile, no Kubernetes; the container, GPUs, scaling, and storage are all configured through Python decorators.

Common reasons to reach for Modal:

- Run AI inference (open-weights or custom models) with GPUs on demand
- Fine-tune or train models without managing infrastructure
- Sandbox untrusted or LLM-generated code
- Schedule batch jobs or cron tasks
- Stand up HTTP endpoints (FastAPI, ASGI, WSGI, raw web servers) backed by GPUs
- Fan out embarrassingly parallel work via `.map()` and `.spawn()`

Modal is Python-only. The `modal` SDK runs locally, ships your code to Modal's cloud, and executes it in containers you described declaratively.

## Installation and Auth

```bash
pip install modal
modal setup           # Opens browser to create/auth a token, writes ~/.modal.toml
```

For CI or scripted environments, set `MODAL_TOKEN_ID` and `MODAL_TOKEN_SECRET` instead.

## The Mental Model

1. You write a Python file with an `App` and one or more decorated functions/classes.
2. Each function is bound to an `Image` (the container) and optional resources (GPU, volumes, secrets, schedule).
3. You either:
   - `modal run script.py` — ephemeral; runs once and tears down (good for dev).
   - `modal serve script.py` — ephemeral; hot-reloads on file changes (good for iterating on web endpoints).
   - `modal deploy script.py` — persistent; the App stays up, accessible by name from anywhere.
4. From local code, call remote functions with `.remote(args)`. From inside Modal containers, you can call other functions the same way.

## Apps and Functions

The minimum viable Modal program:

```python
import modal

app = modal.App("hello")

@app.function()
def square(x: int) -> int:
    return x * x

@app.local_entrypoint()
def main():
    print(square.remote(5))         # runs in the cloud
    print(list(square.map(range(10))))  # parallel fan-out
```

Run it: `modal run script.py`.

### Invocation methods

Called on a function object from local code (or another Modal container):

| Method | Behavior |
|---|---|
| `.remote(*a)` | Run once on Modal, return the result |
| `.local(*a)` | Run in the current process (no Modal involved) |
| `.map(iter)` | Parallel fan-out, results in input order, capped at 1,000 in flight per call |
| `.starmap(iter)` | Like `.map()` but spreads each tuple as args |
| `.for_each(iter)` | Fire-and-forget map; ignores results |
| `.spawn(*a)` | Fire-and-forget single call; returns a `FunctionCall` handle |

For batch work that may include failures, use `.map(inputs, return_exceptions=True)` and inspect each result.

### Local entrypoints

`@app.local_entrypoint()` is the function `modal run` calls by default. Type-annotated parameters become CLI flags:

```python
@app.local_entrypoint()
def main(count: int = 10, name: str = "world"):
    ...
# modal run script.py --count 5 --name Markus
```

## Images

Build images by chaining methods. Modal caches each layer; put fast-changing steps last so caching pays off.

```python
image = (
    modal.Image.debian_slim(python_version="3.12")
    .apt_install("git", "curl")
    .uv_pip_install("torch==2.8.0", "transformers==4.46.0")
    .env({"HF_HOME": "/cache/hf"})
    .add_local_python_source("my_pkg")
)

@app.function(image=image)
def run():
    import torch  # imports needed only on Modal go inside the function
    ...
```

Useful image methods:

- `debian_slim(python_version=...)` — default starting point.
- `from_registry("nvidia/cuda:12.4.0-devel-ubuntu22.04", add_python="3.12")` — start from any public image.
- `from_dockerfile("Dockerfile")` — use an existing Dockerfile.
- `pip_install(...)` / `uv_pip_install(...)` — prefer `uv_pip_install` (faster).
- `apt_install(...)`, `run_commands("...")`, `env({...})`, `workdir("/app")`.
- `add_local_dir(local, remote)`, `add_local_file(local, remote)`, `add_local_python_source("pkg")`.
- `run_function(fn, gpu="A10G", secrets=[...])` — bake state into the image at build time, e.g. download model weights.

Pin versions tightly. Loose pins make builds non-reproducible and surprise you when an upstream release breaks the image.

Pass `force_build=True` to a single layer to bust its cache, or set `MODAL_FORCE_BUILD=1` in the environment.

## GPUs

Set `gpu=` on the function decorator. Common values:

- `T4`, `L4`, `L40S` — cost-effective inference. `L40S` is a strong default for inference.
- `A10G`, `A100`, `A100-40GB`, `A100-80GB` — training and large inference.
- `H100`, `H200`, `B200` — top tier.

Multi-GPU: `gpu="H100:8"`. Fallback list: `gpu=["H100", "A100", "L40S"]` (Modal tries left-to-right). Larger GPU counts mean longer queue waits.

```python
@app.function(image=image, gpu="L40S", timeout=600)
def generate(prompt: str) -> str:
    ...
```

## Class-based Functions and Lifecycle

Use `@app.cls()` when the container needs expensive one-time setup (e.g. loading a model). The container is reused across calls.

```python
@app.cls(image=image, gpu="L40S", scaledown_window=300)
class LLM:
    @modal.enter()
    def load(self):
        from transformers import AutoModelForCausalLM, AutoTokenizer
        self.tok = AutoTokenizer.from_pretrained(MODEL)
        self.model = AutoModelForCausalLM.from_pretrained(MODEL, device_map="cuda")

    @modal.method()
    def generate(self, prompt: str) -> str:
        ...

    @modal.exit()
    def shutdown(self):
        # ~30s grace period; close clients, flush state
        ...
```

Call it: `LLM().generate.remote("hi")`. From local code, instantiate inside a `with app.run():` block or look it up by name (see "Calling deployed code").

For web endpoints on a class, decorate the method with `@modal.fastapi_endpoint()` (or `@modal.asgi_app()` etc.) instead of `@modal.method()`.

## Web Endpoints

Pick the decorator that matches your framework:

| Decorator | Use for |
|---|---|
| `@modal.fastapi_endpoint(method="POST")` | A single endpoint, one function |
| `@modal.asgi_app()` | Full FastAPI / FastHTML / Starlette app |
| `@modal.wsgi_app()` | Django / Flask |
| `@modal.web_server(port=8000)` | Anything that binds its own port (vLLM, Streamlit, ...) |

```python
@app.function(image=image)
@modal.fastapi_endpoint(method="POST")
def chat(payload: dict) -> dict:
    return {"reply": payload["prompt"][::-1]}
```

```python
@app.function(image=image)
@modal.asgi_app()
def fastapi_app():
    from fastapi import FastAPI
    web = FastAPI()

    @web.get("/health")
    def health():
        return {"ok": True}

    return web
```

Iterate locally with `modal serve script.py` — it gives you a temporary URL and hot-reloads on file changes. `modal deploy` gives you a stable URL.

## Concurrency and Scaling

Decorator parameters on `@app.function` / `@app.cls`:

- `min_containers=N` — keep N warm (lower latency, costs money idle).
- `max_containers=N` — cap horizontal scale.
- `buffer_containers=N` — keep N spare so bursts don't queue.
- `scaledown_window=seconds` — how long an idle container stays alive.
- `timeout=seconds` — per-attempt timeout (default 300s, max 86400s).
- `retries=modal.Retries(max_retries=3, backoff_coefficient=2.0, initial_delay=1.0)` — or just `retries=3` for fixed 1s delay.

For IO-bound or batchable workloads, run multiple inputs in one container with `@modal.concurrent`:

```python
@app.function(image=image)
@modal.concurrent(max_inputs=100, target_inputs=50)
async def fetch(url: str) -> str:
    async with httpx.AsyncClient() as c:
        return (await c.get(url)).text
```

Async functions run concurrent inputs as asyncio tasks (single thread); sync functions use threads (must be thread-safe). Async is preferred — a single cancellation kills the whole container in sync mode.

## Storage

### Volumes — persistent, mountable filesystems

Best for model weights, datasets, checkpoints. Write-once / read-many is the sweet spot.

```python
weights = modal.Volume.from_name("model-weights", create_if_missing=True)

@app.function(image=image, gpu="L40S", volumes={"/weights": weights})
def infer():
    # files in /weights persist across runs
    ...
```

Inside a container, call `vol.commit()` to flush writes immediately, `vol.reload()` to pull in changes made by other containers. Background commits run automatically every few seconds.

### Secrets

```python
@app.function(secrets=[modal.Secret.from_name("openai")])
def call_api():
    import os
    key = os.environ["OPENAI_API_KEY"]
```

Other constructors: `Secret.from_dict({...})` (inline, fine for non-sensitive config), `Secret.from_dotenv()` (loads a local `.env`). Multiple secrets are merged in order; later ones override earlier ones.

### Dicts and Queues

Distributed key-value and FIFO primitives for cross-container coordination:

```python
q = modal.Queue.from_name("jobs", create_if_missing=True)
state = modal.Dict.from_name("crawl-state", create_if_missing=True)

q.put({"url": "https://example.com"})
job = q.get()
state["visited"] = state.get("visited", 0) + 1
```

Use `modal.Queue.ephemeral()` / `modal.Dict.ephemeral()` as context managers when you want them only for the lifetime of an `app.run()`.

## Schedules

```python
@app.function(schedule=modal.Cron("0 9 * * *"))   # 9:00 UTC daily
def morning_report():
    ...

@app.function(schedule=modal.Period(hours=6))      # every 6h since deploy
def heartbeat():
    ...
```

`Cron` is anchored to wall-clock time; `Period` resets on redeploy. Schedules only run on deployed apps. To pause one, remove the schedule and redeploy.

## Sandboxes

Use `modal.Sandbox` when you need to run arbitrary or untrusted code (LLM tool use, code interpreters, agentic loops, running a user's repo).

```python
sb = modal.Sandbox.create(
    image=modal.Image.debian_slim().pip_install("numpy"),
    app=app,
    timeout=600,
)
proc = sb.exec("python", "-c", "import numpy; print(numpy.zeros(3))")
print(proc.stdout.read())
sb.terminate()
```

Sandboxes accept the same `image`, `gpu`, `volumes`, `secrets`, and `timeout` as functions. They support file IO via `sb.open()`, network tunnels, and TCP/exec readiness probes. Always `terminate()` (or use as a context manager) so containers don't linger.

## Calling Deployed Code

Once an App is deployed, look up its functions/classes from any other Python process — local script, another Modal app, anywhere with credentials:

```python
fn  = modal.Function.from_name("my-app", "square")
result = fn.remote(7)

LLMCls = modal.Cls.from_name("llm-app", "LLM")
print(LLMCls().generate.remote("hi"))
```

Same `.remote` / `.map` / `.spawn` semantics as the local-defined version.

## CLI Cheatsheet

| Command | What it does |
|---|---|
| `modal setup` | Authenticate, write `~/.modal.toml` |
| `modal token new` | Issue a new token |
| `modal run script.py` | Ephemeral run; calls `local_entrypoint` (or `script.py::fn`) |
| `modal run --detach script.py` | Don't tear down if the local client disconnects |
| `modal serve script.py` | Ephemeral, hot-reloading; for iterating on web endpoints |
| `modal deploy script.py` | Persist the app under its `modal.App("name")` |
| `modal app list` | List apps in the current workspace/environment |
| `modal app stop <name>` | Stop a deployed app |
| `modal app logs <name>` | Tail logs |
| `modal volume create/get/ls/put/rm` | Manage volumes from the shell |
| `modal secret create NAME KEY=val ...` | Create a secret |
| `modal shell script.py::fn` | Open a shell inside that function's image (great for debugging) |

## Idioms Worth Knowing

**Imports for remote-only packages go inside the function body.** Otherwise the local process needs them too.

```python
@app.function(image=image)
def f():
    import torch  # only needed inside the container
    ...
```

**Bake model weights into the image** to avoid downloading on every cold start:

```python
def _download():
    from huggingface_hub import snapshot_download
    snapshot_download("meta-llama/Llama-3.1-8B-Instruct", local_dir="/model")

image = base.run_function(_download, secrets=[modal.Secret.from_name("huggingface")])
```

…or store weights in a `Volume` if you want to swap them without rebuilding the image.

**Fan out, then collect:**

```python
@app.local_entrypoint()
def main():
    results = list(score.map(load_inputs(), return_exceptions=True))
    failures = [r for r in results if isinstance(r, Exception)]
```

**Adjust scale at runtime** (e.g. from a cron job that warms up before peak):

```python
fn = modal.Function.from_name("my-app", "infer")
fn.update_autoscaler(min_containers=10, buffer_containers=2)
```

**Use a class for warm models, a function for stateless work.** If `@modal.enter` takes more than ~1s, you almost certainly want `@app.cls`.

## When to Reach for Reference Docs

Modal's surface area is large and evolves. For anything not covered here — exact parameter signatures, region pinning, OIDC integration, proxy auth tokens, batch processing primitives, custom domains, GPU availability per region — point the user at https://modal.com/docs (guide and reference). Don't guess at parameter names; look them up.
