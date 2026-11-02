# Error


```python
class Error(Exception)
```

Base class for all Modal errors. See [`modal.exception`](https://modal.com/docs/sdk/py/latest/exception)
for the specialized error classes.

**Usage**

```python notest
import modal

try:
    ...
except modal.Error:
    # Catch any exception raised by Modal's systems.
    print("Responding to error...")
```

