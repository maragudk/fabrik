# App API Reference

Work with marimo notebooks programmatically, embed notebooks, and access runtime metadata.

## App Class

### marimo.App

Represents a marimo notebook as a dataflow graph.

```python
import marimo

# In a notebook file
app = marimo.App()

@app.cell
def _():
    x = 42
    return (x,)

@app.cell
def _(x):
    result = x * 2
    return (result,)

if __name__ == "__main__":
    app.run()
```

`App(**kwargs)` accepts these config keys (unknown keys are silently dropped):

```python
app = marimo.App(
    width="medium",          # "compact" (default), "medium", "full", "columns", "normal"
    app_title="My App",      # Browser tab title
    layout_file="layouts/notebook.grid.json",  # Relative to the notebook file
    css_file="custom.css",   # Relative to the notebook file
    html_head_file="head.html",
    auto_download=["html"],  # Any of "html", "markdown", "ipynb"
    sql_output="auto",       # "auto", "polars", "lazy-polars", "pandas", "native"
)
```

## Embedding Notebooks

### app.embed

Embed one notebook's output into another (async). Signature: `embed(defs: dict[str, Any] | None = None) -> AppEmbedResult`.

```python
# Cell 1: import the other notebook
from other_notebook import app as other_app
```

```python
# Cell 2: embed it -- app.embed() can't be called in the cell that imported it
result = await other_app.embed()
result.output  # Visual output
result.defs    # Variable definitions
```

With parameter override:

```python
# Override definitions in embedded notebook
result = await other_app.embed(defs={"threshold": 0.8})

# The embedded notebook runs with threshold=0.8
# instead of its default value
```

To embed independent copies of the same notebook, clone it first:

```python
one = other_app.clone()
r1 = await one.embed()

two = other_app.clone()
r2 = await two.embed()
```

### Nested Embedding

Notebooks can be nested multiple levels:

```python
# notebook_a.py embeds notebook_b.py
# notebook_b.py embeds notebook_c.py
# All work correctly with reactive updates
```

### Interactive Embedded Notebooks

When embedded notebooks contain UI elements, interactions trigger updates:

```python
# other_notebook.py defines a slider
# When embedded, slider interactions update the parent notebook

result = await other_app.embed()
result.output  # Contains interactive slider
# Slider changes propagate reactively
```

## Running Programmatically

### app.run

Execute a notebook and get outputs.

```python
from my_notebook import app

# Run the notebook
outputs, definitions = app.run()

# outputs: Sequence of cell outputs
# definitions: Mapping of variable names to values

print(definitions["result"])  # Access computed value
```

With definition overrides:

```python
# Override input values
outputs, definitions = app.run(defs={
    "input_data": my_data,
    "config": my_config
})

# Cells defining input_data and config are skipped
# Their dependents run with the provided values
```

Overriding is all-or-nothing per cell: if a cell defines `x` and `y`, passing only `x` raises `IncompleteRefsError`. Provide every definition of each overridden cell.

## App Metadata

### mo.app_meta

Access runtime information about the current app.

```python
import marimo as mo

meta = mo.app_meta()
```

### Properties

**mode**: Execution context.

```python
mode = mo.app_meta().mode

# Possible values:
# - "edit": Running in marimo editor
# - "run": Running as app (marimo run)
# - "script": Running as Python script
# - "test": Running in pytest
# - None: Unknown context
```

**theme**: Current display theme.

```python
theme = mo.app_meta().theme

# Possible values:
# - "light"
# - "dark"
# A "system" theme setting currently reports "light"
```

**request**: HTTP request data (in app mode).

```python
request = mo.app_meta().request

# Access request information
request.headers      # HTTP headers (dict)
request.cookies      # Cookies (dict)
request.query_params # URL query parameters (dict of name -> list of values)
request.path_params  # Path parameters from the URL route
request.url          # Dict with "path", "query", "hostname", "port", ...
request.user         # Authenticated user info from auth middleware (if available)
```

## Conditional Behavior

### Based on Mode

```python
mode = mo.app_meta().mode

if mode == "edit":
    # Show debug information
    mo.output.append(f"Debug: {debug_data}")
elif mode == "run":
    # Production app behavior
    pass
elif mode == "script":
    # Script execution
    print("Running as script")
```

### Based on Theme

```python
theme = mo.app_meta().theme

# Adapt visualization colors
if theme == "dark":
    bg_color = "#1a1a1a"
    text_color = "#ffffff"
else:
    bg_color = "#ffffff"
    text_color = "#000000"

# Use in plots
import matplotlib.pyplot as plt
plt.style.use("dark_background" if theme == "dark" else "default")
```

### Based on User

```python
request = mo.app_meta().request

if request and request.user:
    user_name = request.user.get("username", "Guest")
    mo.md(f"Welcome, {user_name}!")
else:
    mo.md("Please log in")
```

## Notebook as Module

Only top-level functions and classes are importable as plain Python objects. Define them with `@app.function` / `@app.class_definition`; they may only reference names from the setup cell or other top-level definitions:

```python
# utils_notebook.py
with app.setup:
    import pandas as pd

@app.function
def process_data(df):
    return df.dropna()

@app.class_definition
class Validator:
    def check(self, df):
        return not df.empty
```

```python
# another file
from utils_notebook import process_data, Validator

result = process_data(my_data)
```

A function defined inside a regular `@app.cell` is NOT importable (`ImportError`).

Named cells can be imported individually as `Cell` objects (the name is the cell's function name):

```python
from utils_notebook import calculate

# Run the cell
output, defs = calculate.run()
result = defs["result"]
```

## Testing Notebooks

```python
# test_notebook.py
import pytest
from my_notebook import app, process_cell

def test_process_cell():
    output, defs = process_cell.run(input_data=[1, 2, 3])
    assert defs["result"] == [2, 4, 6]

def test_full_notebook():
    outputs, defs = app.run(defs={"test_mode": True})
    assert defs["final_result"] is not None
```

## Best Practices

### Design for Embedding

```python
# Good - notebook has clear inputs and outputs
@app.cell
def _(input_data, config):  # Clear inputs
    result = process(input_data, config)
    return (result,)  # Clear output

# Avoid - hidden dependencies
@app.cell
def _():
    global_var = something  # Hard to override
```

### Check Mode Before UI

```python
# Cell 1
mode = mo.app_meta().mode
threshold_ui = mo.ui.slider(0, 1, step=0.1, value=0.5)
threshold_ui if mode != "script" else None
```

```python
# Cell 2 -- read .value in a different cell than the one that created the UI
threshold = (
    float(mo.cli_args().get("threshold", 0.5))
    if mode == "script"
    else threshold_ui.value
)
```

### Handle Missing Request

```python
request = mo.app_meta().request

# Always check for None
if request is not None:
    user = request.user
else:
    user = None
```

### Export Clean APIs

```python
# In notebook, define a top-level function
@app.function
def public_function(data):
    """Process data and return results."""
    return internal_process(data)  # Must itself be top-level or from the setup cell

# Other notebooks or scripts can import and use it
from my_notebook import public_function
```
