# Dynamic Function configuration

Many aspects of a Modal Function's configuration can be dynamically configured from a specific call site. This is useful in cases where the Function's [compute resources](/docs/guide/resources), [secrets](/docs/guide/secrets), [timeout](/docs/guide/timeouts), or other properties need to vary depending on the specific inputs.

## Basic configuration

Features exposed in the [`@app.function()`](/docs/sdk/py/latest/App#function) decorator can be dynamically configured at runtime with the [`modal.Function.with_options()`](/docs/sdk/py/latest/Function#with_options) method.

Say you have the following definition:

```python
@app.function()
def f(x: int) -> int:
    return x ** 2
```

If (for some reason) you wanted to compare this Function's output across several different GPUs, you could invoke it several times with different configurations:

```python continuation
@app.local_entrypoint()
def main():
    for gpu in ["T4", "L4", "A10"]:
        result = f.with_options(gpu=gpu).remote(2)
        print(f"Result with {gpu} GPU: {result}")
```

This example creates three additional variants of the base Function after the App is already running. These variants are *new Functions* that are created on-demand. The base Function itself is not affected. If you invoked `f.remote()` directly, it would continue to execute without a GPU.

Deployed Functions can also be dynamically configured from a call site after a lookup:

```python notest
deployed_f = modal.Function.from_name("demo-app", "f")
for gpu in ["T4", "L4", "A10"]:
    result = deployed_f.with_options(gpu=gpu).remote(2)
    print(f"Result with {gpu} GPU: {result}")
```

## Input concurrency and batching

It's also possible to dynamically configure [input concurrency](/docs/guide/concurrent-inputs) or [batching](/docs/guide/dynamic-batching). As these features are enabled with separate decorators ([`@modal.concurrent()`](/docs/sdk/py/latest/concurrent)/[`@modal.batched()`](/docs/sdk/py/latest/batched)), their dynamic configuration runs through separate methods ([`modal.Function.with_concurrency()`](/docs/sdk/py/latest/Function#with_concurrency)/[`modal.Function.with_batching()`](/docs/sdk/py/latest/Function#with_batching)):

```python notest
concurrent_f = modal.Function.from_name("demo-app", "f").with_concurrency(max_inputs=32)
```

If multiple dynamic configuration methods are called in sequence, their arguments will compose and form a single configuration:

```python notest
# This Function uses a GPU with input concurrency
concurrent_f.with_options(gpu="H100").remote(...)
```

## Autoscaling considerations

Each distinct configuration has its own dedicated autoscaling container pool. By default, the container pool will autoscale according to the configuration of the base Function, with separate accounting. For example, if your Function has `@app.function(max_containers=5)` and you dynamically add a GPU using `f.with_options(gpu="H100")`, you'll get up to 5 *additional* H100 containers regardless of how many CPU containers are currently running.

Try to avoid generating too many fine-grained configurations so that you can benefit from container sharing for higher utilization and reduced cold start latencies. For example, if requesting input-specific `memory=` or `cpu=` resources, it's best to round into coarse buckets.

Functions that have been looked up and dynamically configured in separate processes will still share containers if they apply the same configuration.

If your base Function configuration has `min_containers` set, it will be ignored by the Function variants to avoid creating zombie warm pools. For the same reason, it's not possible to set `min_containers` in `modal.Function.with_options()`.

It is possible to dynamically configure other aspects of autoscaling behavior using `modal.Function.with_options()`. For example, if you don't expect to re-use the variant, you could reduce the `scaledown_window` so that the container shuts down faster. However, if your goal is to use different autoscaling policies over time, it may be simpler to modify the base Function's behavior using [`modal.Function.autoscaler.update`](/docs/sdk/py/latest/Function#autoscalerupdate) instead.

## Dynamic Cls configuration

It's also possible to dynamically configure a `modal.Cls`. If the Cls is [parametrized](/docs/guide/parametrized-functions) (which also creates a new Function variant with its own container pool and autoscaling accounting), the dynamic options will compose with the parameter values:

```python notest
ModelCls = modal.Cls.from_name("demo-app", "ModelCls")
model = ModelCls.with_options(gpu="H100")(size="8B")
```
