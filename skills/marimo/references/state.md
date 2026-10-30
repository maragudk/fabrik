# State API Reference

Advanced state management for synchronizing UI elements and introducing controlled cycles.

**Important**: In over 99% of cases, marimo's built-in reactivity handles state automatically. Only use `mo.state()` for specific edge cases.

## When NOT to Use State

marimo UI elements already have built-in state through `.value`:

```python
# This is sufficient for most cases - no mo.state needed
slider = mo.ui.slider(0, 100)

# In another cell
result = slider.value * 2  # Automatically reactive
```

## When to Use State

Use `mo.state()` only for:

1. **Historical tracking**: Maintaining values beyond UI element state
2. **UI synchronization**: Bidirectionally linking multiple UI elements
3. **Controlled cycles**: Introducing intentional runtime cycles

## Basic Usage

### mo.state

Create reactive state with getter and setter.

```python
import marimo as mo

# Create state with initial value
get_count, set_count = mo.state(0)

# Read state (in any cell)
current = get_count()

# Update state (triggers dependent cells)
set_count(5)

# Functional update
set_count(lambda x: x + 1)
```

### Reactivity rule

When a setter is called in one cell, marimo runs all *other* cells that reference the getter **through a global variable**. So:

- Always assign the getter to a global variable (like a UI element).
- The cell that called the setter is not re-run, even if it reads the getter (unless `allow_self_loops=True`).
- A setter called from an `on_change`/`on_click` callback counts as called from the cell that **defined the UI element**. Display the state in a different cell, or that display won't update.
- Never mutate the state value in place; always go through the setter.

## Synchronizing UI Elements

Link multiple UI elements to the same state:

```python
# Cell 1: Create state
get_value, set_value = mo.state(50)

# Cell 2: Slider linked to state
slider = mo.ui.slider(
    0, 100,
    value=get_value(),
    on_change=set_value
)
slider

# Cell 3: Number input linked to same state
number = mo.ui.number(
    0, 100,
    value=get_value(),
    on_change=set_value
)
number

# Both UI elements stay synchronized
# Changing one updates the other
```

## Tracking History

```python
# Cell 1: State for history
get_history, set_history = mo.state([])

# Cell 2: Button that appends to history
button = mo.ui.button(
    label="Add Entry",
    on_click=lambda _: set_history(lambda h: h + [datetime.now()])
)
button

# Cell 3: Display history
mo.vstack(
    [mo.md(f"Entries: {len(get_history())}")]
    + [mo.md(str(entry)) for entry in get_history()]
)
```

## Parameters

```python
get_value, set_value = mo.state(
    initial_value,
    allow_self_loops=False  # If True, setter can re-run its own cell
)
```

### allow_self_loops

By default, calling `set_value()` doesn't re-run the cell that called it (for UI callbacks, the cell that defined the element). Enable `allow_self_loops=True` to allow this (use with caution to avoid infinite loops).

```python
get_count, set_count = mo.state(0, allow_self_loops=True)

# This cell can trigger itself
button = mo.ui.button(
    label=f"Count: {get_count()}",
    on_click=lambda _: set_count(get_count() + 1)
)
```

## Common Patterns

### Counter

```python
# Cell 1: State and controls
get_count, set_count = mo.state(0)

decrement = mo.ui.button(label="-", on_change=lambda _: set_count(lambda v: v - 1))
increment = mo.ui.button(label="+", on_change=lambda _: set_count(lambda v: v + 1))
mo.hstack([decrement, increment])

# Cell 2: Display (separate cell, so it re-runs on click)
mo.md(f"**{get_count()}**")
```

### Toggle

```python
# allow_self_loops so this cell (which reads the getter) re-runs on click
get_visible, set_visible = mo.state(False, allow_self_loops=True)

toggle = mo.ui.button(
    label="Show" if not get_visible() else "Hide",
    on_click=lambda _: set_visible(not get_visible())
)

mo.vstack([
    toggle,
    mo.md("Content here") if get_visible() else None
])
```

### Form with Reset

```python
# Cell 1: State
get_form_data, set_form_data = mo.state({"name": "", "email": ""})

# Cell 2: Inputs (typing doesn't re-run this cell; reset does)
name = mo.ui.text(
    value=get_form_data()["name"],
    on_change=lambda v: set_form_data({**get_form_data(), "name": v})
)

email = mo.ui.text(
    value=get_form_data()["email"],
    on_change=lambda v: set_form_data({**get_form_data(), "email": v})
)

# Cell 3: Reset button (must not be in Cell 2, or Cell 2 won't re-run)
reset = mo.ui.button(
    label="Reset",
    on_click=lambda _: set_form_data({"name": "", "email": ""})
)

# Cell 4: Layout
mo.vstack([name, email, reset])
```

## Warnings and Best Practices

### Never Store UI Elements in State

```python
# BAD - Don't do this
get_ui, set_ui = mo.state(mo.ui.slider(0, 100))

# GOOD - Store values, create UI separately
get_value, set_value = mo.state(50)
slider = mo.ui.slider(0, 100, value=get_value(), on_change=set_value)
```

### Avoid Infinite Loops

```python
# DANGEROUS with allow_self_loops=True
get_x, set_x = mo.state(0, allow_self_loops=True)
set_x(get_x() + 1)  # Infinite loop!

# SAFE - use conditional
if get_x() < 10:
    set_x(get_x() + 1)
```

### Keep State Minimal

```python
# GOOD - Derive values from state
get_items, set_items = mo.state([])
count = len(get_items())  # Derived, not separate state

# AVOID - Redundant state
get_items, set_items = mo.state([])
get_count, set_count = mo.state(0)  # Redundant
```

### Create UI Elements in Separate Cells

When synchronizing UI elements, create them in separate cells to avoid the setter trying to re-run its own cell:

```python
# Cell 1: State
get_value, set_value = mo.state(50)

# Cell 2: First UI
slider = mo.ui.slider(0, 100, value=get_value(), on_change=set_value)

# Cell 3: Second UI (separate cell!)
number = mo.ui.number(0, 100, value=get_value(), on_change=set_value)
```
