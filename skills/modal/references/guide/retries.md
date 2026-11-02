# Failures and retries

Failure is part of life. Sometimes you just have to retry. This guide page documents how to do this on Modal.

For reference documentation on the `modal.Retries` object, see [this page](/docs/sdk/py/latest/Retries).

## Automatically recover from flakes with `retries`

You can configure Modal to automatically retry Function failures if you set the
`retries` option when declaring your Function:

```python
@app.function(retries=3)
def my_flaky_function():
    pass
```

The basic configuration shown provides a fixed 1s delay between retry attempts.
For fine-grained control over retry delays, including exponential backoff
configuration, use [`modal.Retries`](/docs/sdk/py/latest/Retries).

## Handle failures in `Function.map`

By default, failures are propagated back to the caller.
To treat exceptions like successful results and aggregate them in the results list instead,
pass in [`return_exceptions=True`](/docs/guide/scale#exceptions).

When used with [`Function.map()`](/docs/guide/scale#parallel-execution-of-inputs),
each input is retried independently.

## Container crashes

If a `modal.Function` container crashes (either on start-up, e.g. while handling imports in global scope, or during execution, e.g. an out-of-memory error),
Modal will reschedule the container and any work it was currently assigned.

For [ephemeral Apps](/docs/guide/apps#ephemeral-apps), container crashes will be retried until a failure rate is exceeded,
after which all pending inputs will be failed and the exception will be propagated to the caller.

For [deployed Apps](/docs/guide/apps#deployed-apps), container crashes will be retried indefinitely, so as to not disrupt service.
Modal will instead apply a crash-loop backoff and the rate of new container creation for the Function will be slowed down.
Crash-looping containers are displayed in the [App dashboard](/apps).
