# Modal Functions

Modal Functions execute Python code using highly scalable serverless cloud compute.

Preparing a function to run on Modal is as simple as defining an [App](/docs/guide/apps) and registering the function using the [`@app.function()`](/docs/sdk/py/latest/App#function) decorator:

```python
app = modal.App("basic-function")

@app.function()
def f(x: int, exp: int) -> int:
    return x**exp
```

The wrapped function becomes a [`modal.Function`](/docs/sdk/py/latest/Function) that can be called from a local script or deployed and invoked on demand from other applications as if it were part of their codebase.

When you invoke the Function, Modal handles all of the operational details: booting a container, routing your inputs, and propagating any exceptions. If you don't send more inputs, the Function will automatically scale to zero so that it incurs no ongoing cost. Information about the Function invocation, any logs it produced, and a rich set of container metrics are automatically captured and presented across a number of observability surfaces.

## Configuring the Function runtime

The Function runtime is configured via arguments to the [`@app.function()`](/docs/sdk/py/latest/App#function) decorator. Everything about the container environment and the resources available to the Function can be defined within your Python codebase, without reference to external configuration files.

Functions receive a baseline allotment of [CPU and memory](/docs/guide/resources). Explicit resource configuration is not necessary for simple tasks, because Functions can opportunistically burst above this baseline when needed. Heavier jobs can be provisioned with additional resources to guarantee availability:

```python
@app.function(cpu=16, memory=32768)  # 16 physical cores, 32 GiB of RAM
def f():
    ...
```

Functions can also be provisioned with one or more [GPUs](/docs/guide/gpu):

```python
@app.function(gpu="H200:8")
def f():
    ...
```

To run a Function across multiple GPU nodes, use [`@modal.clustered`](/docs/guide/multi-node-clusters).

Functions execute within arbitrary container environments, as defined by the Function's [Image](/docs/guide/images). Each Function in the App can have its own Image. Images can include resources including Python libraries from PyPI or private repositories, binary dependencies like FFmpeg or OpenCV, and data copied from your local system:

```python
image  = (
    modal.Image.debian_slim()
    .uv_sync()
    .apt_install("ffmpeg")
    .add_local_dir("data", "/data")
)

@app.function(image=image)
def f():
    ...
```

If the Function is provisioned with a GPU, the [CUDA drivers](/docs/guide/cuda) are automatically included.

Modal includes the Function's source in the container by default. Depending on the [project structure](/docs/guide/project-structure), this will be either the script file or entire package where the Function's implementation is defined. As a consequence, Functions do not need to be self-contained and can reference other resources in their module.

Larger datasets, such as model weights, can be mounted into the container using a Modal [Volume](/docs/guide/volumes) or [CloudBucketMount](/docs/guide/cloud-bucket-mounts):

```python
vol = modal.Volume.from_name("model-weights")

@app.function(volumes={"/models": vol})
def f():
    ...
```

Environment variables can be defined in the container runtime by passing them as secure [Secrets](/docs/guide/secrets) or by setting them directly:

```python
api_key = modal.Secret.from_name("api-key")

@app.function(secrets=[api_key], env={"LOG_LEVEL": "info"})
def f():
    ...
```

## Function invocation

Modal Functions are called by one of their [invocation methods](/docs/guide/function-invocation-methods), such as [`f.remote()`](/docs/sdk/py/latest/Function#remote) or [`f.spawn()`](/docs/sdk/py/latest/Function#spawn). When referenced by another Function or local entrypoint in the same App, a Function can be invoked directly:

```python
@app.function()
def f() -> str:
    return "Hello from a Modal container"

@app.function()
def g() -> str:
    return f.remote()

@app.local_entrypoint()
def main():
    print(g.remote())
```

Functions can be invoked from another App or from outside of Modal after a [lookup](/docs/guide/trigger-deployed-functions) using the App and Function names:

```python notest
f = modal.Function.from_name("prod-app", "f")
result = f.remote()
```

Remote lookups and invocations can also be performed via our [JavaScript](/docs/sdk/js/latest) and [Go](/docs/sdk/go/latest) SDKs, allowing you to execute code that leverages Python's AI ecosystem from within applications written in other languages:

<CodeTabs>
  {#snippet javascript()}

```javascript notest
const f = await modal.functions.fromName("prod-app", "f");
result = await f.remote();
```

{/snippet}

{#snippet go()}

```go notest
f, _ := mc.Functions.FromName(ctx, "prod-app", "f", nil)
result, err := f.Remote(ctx, nil, nil)
```

{/snippet} </CodeTabs>

Applying one of the [Web Function](/docs/guide/webhooks) decorators assigns a URL for the Function and allows you to invoke it from anywhere via HTTP:

```python
image = modal.Image.debian_slim().uv_pip_install("fastapi[standard]")

@app.function(image=image)
@modal.fastapi_endpoint()
def f() -> dict[str, str]:
    return {"message": "Hello from a Modal container"}
```

Note that Web Functions are open to the internet by default, but they can optionally require authentication via [Proxy Tokens](/docs/guide/webhook-proxy-auth).

Web Functions are designed for conveniently exposing simple Python functions as web services; use Modal's [Server](/docs/guide/servers) primitive instead for high concurrency or latency-sensitive applications.

Functions can also be automatically invoked on a schedule, akin to a cron job:

```python
@app.function(schedule=modal.Cron("0 6 * * *", timezone="America/New_York"))
def f():
    ...
```

## Execution semantics

Modal Functions abstract several principles of reliable cloud compute orchestration to present an input/output interface that looks like a local Python function call.

Function invocations are automatically authenticated via your Modal token/secret credentials and authorized per your [RBAC](/docs/guide/rbac) configuration. The Function implementation does not need to perform access control.

Modal is responsible for scheduling containers and routing your inputs to them. By default, Function containers can start anywhere in our global fleet, which maximizes availability and minimizes scheduling latency. To constrain container scheduling, e.g. for compliance, [configure the compute and routing regions](/docs/guide/region-selection):

```python
@app.function(region="eu", routing_region="eu-west")
def f():
    ...
```

Note that compute region selection incurs a [pricing multiplier](/docs/guide/region-selection#pricing); routing region selection does not. Region selection also limits the pool of compute, especially when combined with specific GPUs or large resource requests, which can impact scheduling latency.

Because container scheduling is reactive to input load, a container may not be available at the moment of invocation. Inputs will queue in Modal's I/O system until they can be distributed to available containers. If inputs are enqueued too quickly or the queue fills up, they will be rejected with a [`ResourceExhaustedError`](/docs/sdk/py/latest/exception#resourceexhaustederror). For batch workloads, prefer the durable [`f.spawn()`](/docs/sdk/py/latest/Function#spawn) method, which supports higher invocation rates and substantially deeper input queues.

Modal applies an input [timeout](/docs/guide/timeouts) to each invocation; timeouts do not need to be set in the calling context. Timeouts are short by default (5 minutes), but they can be extended up to 24 hours for long-running processes like model training:

```python
@app.function(timeout=86400)  # 24 hours
def f():
    ...
```

Occasionally, containers will fail while executing inputs, e.g. due to [preemption](/docs/guide/preemption) or out-of-memory (OOM) errors. Modal automatically retries any inputs that a container was running when it failed. As a consequence, Function implementations should be idempotent. CPU functions can opt for non-preemptibility, although this incurs a pricing multiplier:

```python
@app.function(nonpreemptible=True)
def f():
    ...
```

Exceptions that originate in the Function's implementation are not automatically retried, but input [retries](/docs/guide/retries) can be enabled:

```python
@app.function(retries=3)
def f():
    ...
```

## Autoscaling and parallelism

Modal Functions autoscale by default. Just as the Function automatically boots a container in response to an initial input, it will boot additional containers if further inputs are received while it is busy. Under ongoing load, the autoscaler will manage the container pool (booting containers or scaling them down) to accommodate fluctuating levels of demand.

Functions expose several options to control the [autoscaling behavior](/docs/guide/scale). Use `min_containers` or `buffer_containers` to reduce cold start penalties by keeping additional idle containers running, and set `max_containers` to limit scaleup under heavy demand:

```python
@app.function(min_containers=1, buffer_containers=1, max_containers=20)
def f():
    ...
```

After a container finishes handling an input, it is available for reuse. Container reuse reduces average latency, because subsequent inputs will be handled immediately instead of waiting for a new container to boot. As load decreases, Modal will gradually scale down containers that are idle, and Functions will eventually scale to zero if inputs cease altogether. The `scaledown_window` controls the aggressiveness of this behavior:

```python
@app.function(scaledown_window=600)  # Idle for longer to better handle sporadic load patterns
def f():
    ...
```

While most Function configuration requires a redeployment to change, the autoscaler parameters can be dynamically updated using [`f.autoscaler.update()`](/docs/sdk/py/latest/Function#autoscalerupdate):

```python notest
f = modal.Function.from_name("prod-app", "f")
f.autoscaler.update(max_containers=50)  # Override the Function's decorator configuration
```

Note that any dynamic updates will be reset by a subsequent deployment.

Because Functions autoscale rapidly, they are a good fit for bursty workloads or batch jobs that require fan-out parallelism. The batch-oriented [`f.map()`](/docs/sdk/py/latest/Function#map) and [`f.spawn_map()`](/docs/sdk/py/latest/Function#spawn_map) methods facilitate parallel execution by efficiently pushing an iterable of inputs into Modal:

```python notest
for result in f.map(inputs):  # Iterate in parallel and handle each result
    ...

f.spawn_map(inputs)  # Higher parallelism with durable semantics for fire-and-forget batch jobs
```

Parallel execution can also be achieved using concurrency patterns. The [`f.spawn()`](/docs/sdk/py/latest/Function#spawn) method returns a [`modal.FunctionCall`](/docs/sdk/py/latest/FunctionCall), which acts like a Future:

```python notest
fc = f.spawn(x)
result = fc.get()
```

Spawning multiple calls allows them to run in parallel:

```python notest
fcs = [f.spawn(x_i) for x_i in xs]
results = modal.FunctionCall.gather(*fcs)
```

Async codebases can also use Modal's [`aio` interface](/docs/guide/async) to apply concurrency patterns with any invocation method:

```python notest
coros = [f.remote.aio(x_i) for x_i in xs]
results = await asyncio.gather(*coros)
```

## Container lifecycle management

While Modal containers boot in less than a second, your application logic may require expensive additional setup, such as loading model weights from disk. By structuring the Function's code as a class and using the [`@app.cls()`](/docs/sdk/py/latest/App#cls) decorator, you can [separate the startup logic](/docs/guide/lifecycle-functions) from the input handling:

```python
@app.cls()
class InferenceEngine:
    @modal.enter()
    def setup(self):
        self.model = load_model()

    @modal.method()
    def predict(self, text: str) -> float:
        return self.model.predict(text)
```

In this example, the method wrapped with the [`@modal.enter()`](/docs/sdk/py/latest/enter) decorator will run only once, as part of container startup. The container will not be considered "ready" until the startup method or methods complete, and Modal will wait for this event before sending the container any inputs.

A Cls is invoked by "constructing" the class and calling the method decorated with [`@modal.method()`](/docs/sdk/py/latest/method). As with normal Functions, this can be a local reference or a lookup:

```python notest
result = InferenceEngine().predict.remote(text)  # Refer to a Cls on the same App

InferenceEngine = modal.Cls.from_name("prod-app", "InferenceEngine")
result = InferenceEngine().predict.remote(text)  # Refer to a Cls via a lookup
```

Structuring your code as a class also lets you define container teardown logic in methods wrapped with the [`@modal.exit()`](/docs/sdk/py/latest/exit) decorator. This is useful for cleanup operations like gracefully closing connections to databases. The exit handler can also be used to make your application more resilient to [container preemption](/docs/guide/preemption).

Any state written to the `self` namespace will persist across the calls handled by an individual container, but it will be discarded when the container terminates. State can be shared across containers using Modal's distributed [Dict](/docs/guide/dicts) or [Queue](/docs/guide/queues) primitives.

If the Function produces local state that should not leak across inputs, you can set `single_use_containers=True`. This causes each container to terminate after handling an input. Note that single-use containers add some latency and cost, since they do not benefit from amortizing container startup over multiple inputs.

## Function parametrization

To write templated container lifecycle logic, add [`modal.parameter()`](/docs/sdk/py/latest/parameter) declarations to the class:

```python
@app.cls()
class InferenceEngine:
    model_name: str = modal.parameter()

    @modal.enter()
    def startup(self):
        self.model = load_model(self.model_name)

    @modal.method()
    def predict(self, input: str) -> float:
        ...
```

This creates a [Parametrized Function](/docs/guide/parametrized-functions). Supply values for the parameters when constructing the Cls in a calling context, which creates a specific instance of the Function:

```python notest
result = InferenceEngine(model_name="tts-large").predict.remote(text)
```

Because the parameters apply to the entire container lifecycle, every distinct set of parameter values corresponds to a separate, independently autoscaling *container pool*. This can also be leveraged to partition a Function's containers, even when the parameter values are not read at startup. For example, you may wish to process data from different customers in separate containers:

```python notest
result = PartitionedInferenceEngine(customer_id="c-024").predict.remote(text)
```

Note that there is a limit on the number of distinct instances each Function can have, so this approach is only suited for partitioning schemes with relatively low cardinality. Prefer using `single_use_containers=` for container isolation when parameter values would not frequently recur and benefit from container reuse.

## Dynamic configuration

Updating configuration values in the [`@app.function()`](/docs/sdk/py/latest/App#function) decorator requires a [redeployment](/docs/guide/managing-deployments), but it's also possible to [dynamically configure](/docs/guide/dynamic-function-config) the Function from a call site using [`f.with_options()`](/docs/sdk/py/latest/Function#with_options). This is useful in cases where specific inputs or parameter values require different resources, such as different GPUs:

```python notest
result = InferenceEngine(model_name="tts-large").predict.remote(text)

InferenceEngineH200 = InferenceEngine.with_options(gpu="H200")
result = InferenceEngineH200(model_name="tts-xlarge").predict.remote(text)
```

As with Parametrized Functions (but unlike updates to the autoscaler configuration), each distinct set of dynamic options corresponds to an independent container pool. If dynamically configuring CPU or memory, use a coarse set of values to benefit from container reuse.

## Concurrency and batching

By default, each Function container will handle one input at a time. Functions support two distinct patterns for handling multiple inputs.

[Input concurrency](/docs/guide/concurrent-inputs), enabled using the [`@modal.concurrent()`](/docs/sdk/py/latest/concurrent) decorator, allows Functions to accept multiple inputs and execute them concurrently using either threads or asyncio tasks:

```python
@app.function()
@modal.concurrent(max_inputs=10)
def f(x):
    ...  # Sync implementation; each input runs in its own thread

@app.function()
@modal.concurrent(max_inputs=10)
async def g(x):
    ...  # Async implementation; each input runs on the main thread in an asyncio task
```

Functions can benefit from input concurrency if they are I/O bound, e.g. because they make network requests or database queries. Some GPU frameworks can also benefit from input concurrency via continuous batching. Input concurrency is less likely to be useful if the Function is CPU bound.

An alternative strategy is [dynamic batching](/docs/guide/dynamic-batching), enabled using the [`@modal.batched()`](/docs/sdk/py/latest/batched) decorator. A batched Function must be defined as accepting a list (or lists) of inputs and returning a list of outputs:

```python
@app.function()
@modal.batched(max_batch_size=4, wait_ms=1000)
def f(x: list[int], y: list[int]) -> list[int]:
    return [x_i + y_i for x_i, y_i in zip(x, y)]
```

When calling a batched Function, inputs are sent individually, buffered by Modal until the batch size is filled or the wait period elapses, and then processed in a single function call. From the perspective of any individual caller, this looks no different from a normal Function invocation:

```python notest
xy_sum = f.remote(2, 6)
```

Dynamic batching is especially useful in cases where you can leverage vectorization via tensor or array frameworks like torch or numpy.
