# current_function_call_id

```python
current_function_call_id()
```
Returns the function call ID for the current input.

Can only be called from Modal function (i.e. in a container context).

```python
from modal import current_function_call_id

@app.function()
def process_stuff():
    print(f"Starting to process input from {current_function_call_id()}")
```
