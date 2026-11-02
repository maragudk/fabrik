# Retries


```python
class Retries(object)
```

Adds a retry policy to a Modal function.

**Usage**

```python
import modal
app = modal.App()

# Basic configuration.
# This sets a policy of max 4 retries with 1-second delay between failures.
@app.function(retries=4)
def f():
    pass


# Fixed-interval retries with 3-second delay between failures.
@app.function(
    retries=modal.Retries(
        max_retries=2,
        backoff_coefficient=1.0,
        initial_delay=3.0,
    )
)
def g():
    pass


# Exponential backoff, with retry delay doubling after each failure.
@app.function(
    retries=modal.Retries(
        max_retries=4,
        backoff_coefficient=2.0,
        initial_delay=1.0,
    )
)
def h():
    pass
```

```python
__init__(self, *, max_retries, backoff_coefficient=2.0, initial_delay=1.0,
    max_delay=60.0)
```
Construct a new retries policy, supporting exponential and fixed-interval delays via a backoff coefficient.

**Parameters**

<Parameter name="max_retries" type="int" description="Maximum number of retries after failures." />
<Parameter name="backoff_coefficient" type="float" defaultValue="2.0" description="Multiplier applied to the delay after each attempt; ``1.0`` means fixed delay." />
<Parameter name="initial_delay" type="float" defaultValue="1.0" description="Seconds before the first retry." />
<Parameter name="max_delay" type="float" defaultValue="60.0" description="Upper cap on the delay between retries (seconds)." />
