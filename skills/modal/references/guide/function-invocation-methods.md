# Function invocation methods

Modal [Functions](/docs/guide/functions) expose several different invocation methods. These methods have semantics that vary across multiple dimensions. Understanding how they vary will let you choose the method that is most appropriate for particular use cases.

## Synchronous vs. asynchronous

Function invocations are either synchronous or asynchronous from the perspective of the calling process. Synchronous methods wait for the remote process to complete before returning the result, while asynchronous methods send the input and immediately return a [`modal.FunctionCall`](/docs/sdk/py/latest/FunctionCall) handle. This handle can be used to poll for progress or retrieve the result at a later time.

Note that this synchronous/asynchronous distinction is unrelated to Modal's [`.aio` interface](/docs/guide/async). The `.aio` interface affects only the mechanism of execution in the local process, not how the call is handled by Modal's systems. It also does not matter whether the Function's implementation is written using async Python.

Synchronous and asynchronous invocations differ in terms of their scalability, durability, and latency.

### Scalability

Synchronous invocations are subject to stricter platform limits:

* No more than 2,000 synchronous inputs may be queued and waiting for a container at any one time.
* No more than 25,000 synchronous inputs in total may be in the system (queued or running) at any one time.

In contrast, up to 1 million inputs can be queued for asynchronous execution, so asynchronous methods are a better choice whenever you have a large batch of inputs to process.

Function calls are also subject to *rate* limits, which are higher for asynchronous invocations. As a baseline, Modal supports synchronous invocations at a rate of 200/s and asynchronous invocations at a rate of 1,500/s.

If a function call exceeds any of these limits, it will be rejected with a [`ResourceExhaustedError`](/docs/sdk/py/latest/exception#resourceexhaustederror). In some cases, the Modal SDK will handle this error and retry with backoff, adding latency. The exception may also be propagated to user code.

### Durability

Inputs sent via asynchronous methods are more durable. Asynchronous function calls are "fire-and-forget" and will continue running if the calling process exits, but synchronous invocations will be cancelled within two minutes after the caller hangs up.

The result payload for asynchronous invocations will be stored for 7 days, although the input payload will be discarded after the call completes successfully. Synchronous invocations are not stored in Modal's systems after being sent back to the caller.

### Latency

Because they are handled more durably, asynchronous invocations have higher latency. For many compute-intensive applications, the difference will be negligible, but latency-sensitive applications should prefer synchronous invocation methods.

Note that the synchronous I/O system still imposes some overhead to support its stateful input queue. Where request latency is at an absolute premium, prefer using Modal's [Server](/docs/guide/servers) primitive instead.

## Singular vs. batched

Several invocation methods accept a *batch* of inputs rather than a single input payload. These methods abstract away the mechanics involved in efficiently and reliably sending multiple inputs to Modal.

Note that each input in the batch will still be *handled* separately: this is a distinct concept from [dynamic batching](/docs/guide/dynamic-batching).

## Invocation methods

The primary [`modal.Function`](/docs/sdk/py/latest/Function) invocation methods occupy the following positions in a 2x2 matrix:

|          | Synchronous                                                | Asynchronous                                                     |
| -------- | ---------------------------------------------------------- | ---------------------------------------------------------------- |
| Singular | [`Function.remote()`](/docs/sdk/py/latest/Function#remote) | [`Function.spawn()`](/docs/sdk/py/latest/Function#spawn)         |
| Batched  | [`Function.map()`](/docs/sdk/py/latest/Function#map)       | [`Function.spawn_map()`](/docs/sdk/py/latest/Function#spawn_map) |

### `Function.remote`

Invoking a Function with [`Function.remote()`](/docs/sdk/py/latest/Function#remote) makes a synchronous call, sending the input payload and waiting for the remote process to complete before returning. It is the most basic method for running compute on Modal because its semantics are closest to a local function call:

```python
@app.function()
def f(x: int) -> int:
    return x ** 2


@app.local_entrypoint()
def main():
    res = f.remote(2)
    assert res == 4
```

The related [`Function.remote_gen()`](/docs/sdk/py/latest/Function#remote_gen) method also sends the input synchronously, but it works when the remote Function is a generator that yields results back to the caller:

```python
@app.function()
def g(x: int) -> int:
    for n in range(4):
        yield x ** n

@app.local_entrypoint()
def main():
    res = g.remote_gen(2)
    assert list(res) == [1, 2, 4, 8]
```

### `Function.spawn`

The asynchronous [`Function.spawn()`](/docs/sdk/py/latest/Function#spawn) method sends its input to the Function and immediately returns a [`modal.FunctionCall`](/docs/sdk/py/latest/FunctionCall) object representing that input.

You can retrieve the result by calling [`FunctionCall.get()`](/docs/sdk/py/latest/FunctionCall#get):

```python
def spawn_and_fetch(x):
    fc = f.spawn(x)
    return fc.get()
```

By default, [`FunctionCall.get()`](/docs/sdk/py/latest/FunctionCall#get) will block until the result is available. This is similar to synchronous invocation, although it trades off some latency for scalability and durability. You can also pass a timeout to implement a polling pattern:

```python
def spawn_and_poll(x):
    fc = f.spawn(x)
    while True:
        try:
            return fc.get(timeout=1)
        except TimeoutError:
            print("Not finished yet")
```

For long-running Functions, you may not want the calling process to wait until the result is available. To facilitate this, you can store the FunctionCall's object ID and use it to fetch the result in another context:

```python
def spawn_input(x):
    fc = f.spawn(x)
    return fc.object_id

def fetch_result(fc_id):
    fc = modal.FunctionCall.from_id(fc_id)
    return fc.get()
```

Because it offers increased scalability and durability, [`Function.spawn()`](/docs/sdk/py/latest/Function#spawn) is often a better choice than [`Function.remote()`](/docs/sdk/py/latest/Function#remote) for compute-intensive applications, especially those that require high fan-out or complex orchestration.

### `Function.map`

The batched [`Function.map()`](/docs/sdk/py/latest/Function#map) method makes it easy to leverage Modal's horizontal scalability by consuming an iterable of inputs in a single invocation:

```python
@app.function()
def f(x: int) -> int:
    return x ** 2

@app.local_entrypoint()
def main():
    res = f.map(range(1, 5))
    assert list(res) == [1, 4, 9, 16]
```

Modal will spin up multiple containers to process the map in parallel.

The [`Function.map()`](/docs/sdk/py/latest/Function#map) invocation is synchronous, which has consequences for its scalability. Input submission is subject to the rate limits mentioned [above](#scalability), and each invocation can run at most 1,000 inputs concurrently. For convenience, the Modal SDK internally handles system back-pressure to avoid tripping limits on input submission rate or input queue depth while running a map. But the limits may prevent [`Function.map()`](/docs/sdk/py/latest/Function#map) invocations from immediately scaling up and utilizing available container capacity.

The [`Function.starmap()`](/docs/sdk/py/latest/Function#starmap) method has equivalent semantics, but it consumes an iterable where each entry is a *sequence of arguments*, effectively doing `[f.remote(*args) for args in input_list]` in parallel.

### `Function.spawn_map`

The [`Function.spawn_map()`](/docs/sdk/py/latest/Function#spawn_map) method combines the asynchronous semantics of [`Function.spawn()`](/docs/sdk/py/latest/Function#spawn) with the batched semantics of [`Function.map`](/docs/sdk/py/latest/Function#map). Like [`Function.map`](/docs/sdk/py/latest/Function#map), it applies the Function to each entry in an iterable of inputs:

```python
def load_inputs(filenames):
    for fname in filenames:
        yield load(fname)

def spawn_batch(filenames):
    f.spawn_map(load_inputs(filenames))
```

Because platform limits are higher for asynchronous invocations, [`Function.spawn_map`](/docs/sdk/py/latest/Function#spawn_map) sends the entire iterable of inputs as fast as possible, taking maximum advantage of Modal's elastic compute.

As yet, [`Function.spawn_map()`](/docs/sdk/py/latest/Function#spawn_map) does not return a FunctionCall handle, so it is currently useful only when the Function has side effects like writing its result to durable storage. This will be improved in the future.

### `Function.local`

Unlike the other methods, [`Function.local()`](/docs/sdk/py/latest/Function#local) always executes in the same environment as the caller (whether that is on your system or inside a Modal container). Invoking [`Function.local()`](/docs/sdk/py/latest/Function#local) is equivalent to calling the unwrapped underlying function directly; none of the Modal configuration will apply.
