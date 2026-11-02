# concurrent

```python
concurrent(*, max_inputs=None, target_inputs=None)
```
Decorator that allows individual containers to handle multiple inputs concurrently.

The concurrency mechanism depends on whether the function is async or not:
- Async functions will run inputs on a single thread as asyncio tasks.
- Synchronous functions will use multi-threading. The code must be thread-safe.

Input concurrency will be most useful for workflows that are IO-bound
(e.g., making network requests) or when running an inference server that supports
dynamic batching.

When `target_inputs` is set, Modal's autoscaler will try to provision resources
such that each container is running that many inputs concurrently, rather than
autoscaling based on `max_inputs`. Containers may burst up to up to `max_inputs`
if resources are insufficient to remain at the target concurrency, e.g. when the
arrival rate of inputs increases. This can trade-off a small increase in average
latency to avoid larger tail latencies from input queuing.

*Added in v0.73.148:* This decorator replaces the `allow_concurrent_inputs` parameter
in `@app.function()` and `@app.cls()`.

**Usage**

```python
# Stack the decorator under `@app.function()` to enable input concurrency
@app.function()
@modal.concurrent(max_inputs=100)
async def f(data):
    # Async function; will be scheduled as asyncio task
    ...

# With `@app.cls()`, apply the decorator at the class level, not on individual methods
@app.cls()
@modal.concurrent(max_inputs=100, target_inputs=80)
class C:
    @modal.method()
    def f(self, data):
        # Sync function; must be thread-safe
        ...

```
