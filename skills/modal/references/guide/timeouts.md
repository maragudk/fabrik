# Timeouts

All Modal [Function](/docs/sdk/py/latest/Function) executions have a default
execution timeout of 300 seconds (5 minutes), but users may specify timeout
durations between 1 second and 24 hours.

```python
import time


@app.function()
def f():
    time.sleep(599)  # Timeout!


@app.function(timeout=600)
def g():
    time.sleep(599)
    print("*Just* made it!")
```

The timeout duration is a measure of a Function's *execution* time. It does not
include scheduling time or any other period besides the time your code is
executing in Modal. This duration is also per execution attempt, meaning
Functions configured with [`modal.Retries`](/docs/sdk/py/latest/Retries) will
start new execution timeouts on each retry. For example, an infinite-looping
Function with a 100 second timeout and 3 allowed retries will run for least 400
seconds within Modal.

### Container startup timeout

A Function's `startup_timeout` configures the container's *startup* time. Your container
may be taking a long time to startup because it is loading large data, initializing a
large model or importing many packages. In these cases, you can extend the
`startup_timeout` of your Function.

```python
@app.cls(startup_timeout=30, timeout=10)
class MyFunction:
    @modal.enter()
    def startup(self):
        time.sleep(20)

    @modal.method()
    def f(self):
        time.sleep(1)
```

`startup_timeout` was added in v1.1.4. Prior to v1.1.4, `timeout` configures the
*execution* time and *startup* time. If `startup_timeout` is not set, `timeout` will
still configure both times.

## Handling timeouts

After exhausting any specified retries, a timeout in a Function will produce a
`modal.exception.FunctionTimeoutError` which you may catch in your code.

```python
import modal.exception


@app.function(timeout=100)
def f():
    time.sleep(200)  # Timeout!


@app.local_entrypoint()
def main():
    try:
        f.remote()
    except modal.exception.FunctionTimeoutError:
        ... # Handle the timeout.
```

## Timeout accuracy

Functions will run for *at least* as long as their timeout allows, but they may
run a handful of seconds longer. If you require accurate and precise timeout
durations on your Function executions, it is recommended that you implement
timeout logic in your user code.
