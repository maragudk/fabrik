# Control Flow API Reference

Control cell execution flow with conditional stops, gating, and threading.

## Conditional Execution

### mo.stop

Halt cell execution based on a condition.

```python
import marimo as mo

# Stop if condition is true
mo.stop(data is None)

# Stop with message
mo.stop(
    not data_loaded,
    mo.md("**Loading data...** Please wait.")
)

# Stop with UI element
mo.stop(
    form.value is None,
    mo.md("**Submit the form to continue.**")
)
```

When `mo.stop()` triggers:
1. A `MarimoStopError` is raised
2. Cell execution halts
3. The optional output is displayed
4. Downstream cells don't run (their definitions are removed)

### Common Patterns

**Gate on button click:**

```python
run_button = mo.ui.run_button(label="Run Analysis")

# In another cell
mo.stop(not run_button.value, mo.md("Click **Run Analysis** to proceed."))

# Expensive computation runs only after button click
result = expensive_analysis(data)
```

**Gate on form submission:**

```python
form = mo.ui.text(label="Enter query").form()

# In another cell
mo.stop(form.value is None, mo.md("Submit a query to search."))

results = search(form.value)
```

**Gate on data availability:**

```python
mo.stop(
    df is None or len(df) == 0,
    mo.callout("No data available. Upload a file to continue.", kind="warn")
)

# Process data
summary = df.describe()
```

**Multiple conditions:**

```python
errors = []
if not username:
    errors.append("Username required")
if not password:
    errors.append("Password required")

mo.stop(
    len(errors) > 0,
    mo.callout(mo.md("\n".join(f"- {e}" for e in errors)), kind="danger")
)
```

## Periodic Execution

### mo.ui.refresh

Trigger cell re-execution at intervals. The element is a button with an interval dropdown; it ticks in the frontend, so it must be displayed.

```python
# Auto-refresh every 5 seconds (number of seconds or a string like "5s", "1m 30s")
refresh = mo.ui.refresh(default_interval=5)
refresh

# With a choice of intervals (default_interval must be one of the options;
# the dropdown adds its own "off" choice, so don't pass "off")
refresh = mo.ui.refresh(
    options=["1s", "5s", "10s", "30s"],
    default_interval="5s",
)
refresh

# In another cell - reference refresh to re-run on every tick
_ = refresh.value  # "" before the first tick, then e.g. "5s (3)"
current_time = datetime.now()
latest_data = fetch_data()
```

## Runtime Configuration

### Lazy Execution Mode

Set "On cell change" to "lazy" in the notebook settings (or the notebook footer) to mark dependent cells as stale instead of auto-running them. Running a cell with stale ancestors runs those ancestors first; the run button runs all stale cells.

```toml
# pyproject.toml (or the notebook's PEP 723 metadata)
[tool.marimo.runtime]
on_cell_change = "lazy"   # default: "autorun"
```

Useful for:
- Expensive computations
- Debugging
- Step-by-step execution

### Disable Autorun on Startup

Toggle the "On startup" setting (config key `auto_instantiate`) to stop `marimo edit` from running the notebook when it opens. Neither setting affects apps served with `marimo run`.

### Disable Individual Cells

Disable a cell from the editor's cell menu, or with `@app.cell(disabled=True)` in the file. A disabled cell and its descendants don't run.

## Threading

### mo.Thread

Extended threading with frontend communication.

```python
import marimo as mo

def worker():
    thread = mo.current_thread()
    for i in range(100):
        if thread.should_exit:
            # Cleanup and exit
            return
        # Do work
        mo.output.append(f"Progress: {i}%")

thread = mo.Thread(target=worker)
thread.start()
```

Properties:
- `should_exit`: Returns `True` when cell becomes invalid (re-run, deleted, interrupted)

Features:
- `mo.output.append()` and `print()` forward to frontend
- Must implement cleanup when `should_exit` is `True`

### mo.current_thread

Get the current marimo thread context.

```python
def worker():
    thread = mo.current_thread()
    while not thread.should_exit:
        # Process items
        pass

# Raises RuntimeError if not in a marimo thread
```

## Error Handling

```python
try:
    result = risky_operation()
except Exception as e:
    mo.stop(True, mo.callout(f"Error: {e}", kind="danger"))

# Continue with result
process(result)
```

## Combining Control Flow

```python
# Complex gating example
file = mo.ui.file(filetypes=[".csv"])  # value is an empty tuple until upload
run_btn = mo.ui.run_button(label="Analyze")

mo.vstack([file, run_btn])

# In processing cell
mo.stop(not file.value, mo.md("Upload a CSV file"))
mo.stop(not run_btn.value, mo.md("Click **Analyze** to process"))

# Both conditions met - process
df = pd.read_csv(io.BytesIO(file.contents()))
analysis = analyze(df)
```

## Best Practices

1. **Use mo.stop() for prerequisites**: Gate expensive operations until dependencies are ready
2. **Provide clear feedback**: Always include informative output in `mo.stop()`
3. **Use run_button for expensive ops**: Don't auto-run costly computations
4. **Handle thread cleanup**: Always check `should_exit` in long-running threads
5. **Prefer reactivity over manual control**: Let marimo's DAG handle most execution flow
