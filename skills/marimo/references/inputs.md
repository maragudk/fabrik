# Inputs API Reference

All input elements are available under `mo.ui`. Each element has a `.value` property that updates reactively when users interact with them.

## Common Patterns

```python
import marimo as mo

# Create element and display it
slider = mo.ui.slider(0, 100)
slider  # Display in cell

# Access value in another cell
result = slider.value * 2
```

All inputs support:
- `.form()` - Wrap in a submittable form
- `.batch()` - Combine with other elements
- `.style()` - Apply CSS styles

Most inputs also accept:
- `on_change` - Callback when value changes
- `label` - Markdown label text
- `disabled` - Render the element read-only

## Numeric Inputs

### slider

Numeric value selection across an interval.

```python
# Basic slider
slider = mo.ui.slider(start=0, stop=100, value=50)

# With step
slider = mo.ui.slider(start=0, stop=100, step=5)

# Custom steps (e.g., logarithmic)
import numpy as np
slider = mo.ui.slider(steps=np.logspace(0, 3, 10))

# From DataFrame column
slider = mo.ui.slider.from_series(df["column"])

# With options
slider = mo.ui.slider(
    start=0, stop=100,
    value=50,
    label="Select value",
    show_value=True,        # Display current value
    include_input=True,     # Editable input field
    debounce=True,          # Update only on release
    orientation="vertical", # or "horizontal"
    full_width=True
)
```

### range_slider

Select a range of values.

```python
range_slider = mo.ui.range_slider(start=0, stop=100, value=[20, 80])
# Access: range_slider.value returns [low, high]
```

### number

Numeric input field with optional bounds.

```python
number = mo.ui.number(start=0, stop=100, value=50)
number = mo.ui.number(start=0, stop=100, step=0.1, label="Enter value")
```

### matrix

Matrix or vector editor; drag an entry horizontally to change it, double-click to type a value.

```python
mat = mo.ui.matrix([[1, 0], [0, 1]])
mat = mo.ui.matrix(
    [[1, 0], [0, 1]],         # Lists, NumPy arrays, or tensors
    min_value=-10,
    max_value=10,
    step=0.5,                 # Scalars or element-wise arrays
    disabled=[[True, False], [False, True]],  # Element-wise lock mask
    symmetric=True,           # Mirror edits across the diagonal
    precision=2,
    row_labels=["x", "y"],
    column_labels=["a", "b"],
)
# Access: mat.value returns a list of lists
# A flat list, e.g. mo.ui.matrix([1, 2, 3]), shows a column vector and .value is a flat list
```

## Text Inputs

### text

Single-line text input.

```python
text = mo.ui.text(placeholder="Enter name")
text = mo.ui.text(value="default", label="Name", max_length=100)
text = mo.ui.text(kind="password")  # or "email", "url"
```

### text_area

Multi-line text input.

```python
textarea = mo.ui.text_area(placeholder="Enter description", rows=5)
textarea = mo.ui.text_area(value="", max_length=1000)
```

### code_editor

Syntax-highlighted code editor.

```python
editor = mo.ui.code_editor(language="python", value="def hello():\n    pass")
editor = mo.ui.code_editor(
    language="sql",
    theme="dark",
    min_height=200
)
```

## Selection Inputs

### dropdown

Single selection from options.

```python
dropdown = mo.ui.dropdown(["Option A", "Option B", "Option C"])
dropdown = mo.ui.dropdown(
    options={"Display A": "value_a", "Display B": "value_b"},
    value="Display A",  # Initial value is a key; .value returns "value_a"
    label="Select option",
    searchable=True,
    allow_select_none=True
)
```

### multiselect

Multiple selection from options.

```python
multiselect = mo.ui.multiselect(["A", "B", "C", "D"])
multiselect = mo.ui.multiselect(
    options=["A", "B", "C"],
    value=["A", "B"],  # Pre-selected
    max_selections=2
)
```

### radio

Radio button group.

```python
radio = mo.ui.radio(["Option 1", "Option 2", "Option 3"])
radio = mo.ui.radio(
    options={"First": 1, "Second": 2},
    value="First",  # Initial value is a key; .value returns 1
    inline=True  # Horizontal layout
)
```

### checkbox

Single checkbox.

```python
checkbox = mo.ui.checkbox(label="I agree to terms")
checkbox = mo.ui.checkbox(value=True)  # Pre-checked
```

### switch

Toggle switch.

```python
switch = mo.ui.switch(label="Enable feature")
switch = mo.ui.switch(value=True)
```

## Date and Time

### date

Date picker.

```python
from datetime import date

date_picker = mo.ui.date(label="Select date")
date_picker = mo.ui.date(
    value=date.today(),
    start=date(2020, 1, 1),
    stop=date(2030, 12, 31)
)
```

### datetime

Date and time picker.

```python
datetime_picker = mo.ui.datetime(label="Select date and time")
datetime_picker = mo.ui.datetime(precision="second")  # "hour", "minute" (default), "second"
```

### date_range

Date range selection.

```python
date_range = mo.ui.date_range(label="Select period")
# Access: date_range.value returns a (start_date, end_date) tuple
```

## Buttons

### button

Clickable button with optional value.

```python
button = mo.ui.button(label="Click me")
button = mo.ui.button(
    label="Submit",
    value=0,
    on_click=lambda value: value + 1,  # Increment on click
    kind="success",                    # "neutral", "success", "warn", "danger"
    tooltip="Submit the form",
    keyboard_shortcut="Ctrl-Enter"
)
```

### run_button

Button that gates cell execution.

```python
run_button = mo.ui.run_button(label="Run analysis")
# Use with mo.stop(); value is True after a click, then resets to False
mo.stop(not run_button.value, mo.md("Click to run"))
```

### refresh

Auto-refresh button with interval. Cells that reference it re-run on every tick.

```python
refresh = mo.ui.refresh(default_interval=5)  # Refresh every 5 seconds
refresh = mo.ui.refresh(
    options=["1s", "5s", "1m 30s"],  # Seconds as numbers, or strings like "1m"
    default_interval="5s"
)
# Access: refresh.value is "" before the first tick, then e.g. "5s (3)"
```

## File Inputs

### file

File upload.

```python
file = mo.ui.file(filetypes=[".csv", ".json"])
file = mo.ui.file(
    filetypes=[".csv"],
    multiple=True,  # Allow multiple files
    kind="area",    # Drag-and-drop area instead of a button
    max_size=10_000_000,  # Bytes; default 100 MB
    label="Upload data"
)
# Access: file.value returns list of file objects
# Each has .name, .contents (bytes)
# Shortcuts: file.name(index=0), file.contents(index=0)
```

### file_browser

Browse server-side files: local, or S3/GCS/Azure via a `cloudpathlib` path.

```python
browser = mo.ui.file_browser(initial_path="./data")
browser = mo.ui.file_browser(
    initial_path=".",
    filetypes=[".py", ".md"],
    selection_mode="file",    # "file", "directory", or "all"
    multiple=True,            # Default True
    restrict_navigation=True  # Default True; prevent navigating above initial_path
)
# Access: browser.path(index=0) returns a Path, browser.name(index=0) the file name
```

### microphone

Audio recording.

```python
mic = mo.ui.microphone(label="Record audio")
# Access: mic.value returns an io.BytesIO; play it back with mo.audio(mic.value)
```

## Data Inputs

### table

Interactive data table with row selection.

```python
table = mo.ui.table(df)
table = mo.ui.table(
    data=df,
    selection="multi",        # "single", "multi", "single-cell", "multi-cell", None
    pagination=True,
    page_size=10,
    show_column_summaries=True,  # or "stats", "chart"
    show_data_types=True,
    initial_selection=[0, 2],  # Pre-select rows
    freeze_columns_left=["id"],
    max_height=400
)
# Access: table.value returns selected rows as DataFrame
```

Table formatting:

```python
table = mo.ui.table(
    data=df,
    format_mapping={
        "price": "${:.2f}",
        "date": lambda x: x.strftime("%Y-%m-%d"),
    },
    # Called with (row_id, column_name, value); returns CSS properties
    style_cell=lambda row, col, val: {"backgroundColor": "yellow"} if col == "price" and val > 100 else {}
)
```

### dataframe

No-code DataFrame transformations.

```python
df_editor = mo.ui.dataframe(df)
df_editor = mo.ui.dataframe(
    df,
    page_size=10,
    show_download=True,
    lazy=True  # Show "Apply" button; default None infers from data size
)
# Access: df_editor.value returns transformed DataFrame
```

Supported transformations: Filter, Select, Rename, Convert, Sort, Group By, Aggregate, Sample, Shuffle, Explode, Expand Dict, Unique, Pivot.

### data_explorer

Full data exploration interface.

```python
explorer = mo.ui.data_explorer(df)
explorer = mo.ui.data_explorer(df, x="col_a", y="col_b", color="col_c")  # Initial encodings
# Access: explorer.value returns the chart specification dict
```

### data_editor

Edit tabular data in a spreadsheet-like grid (experimental).

```python
editor = mo.ui.data_editor(df)  # Eager DataFrame, list of dicts, or dict of lists
editor = mo.ui.data_editor(data, editable_columns=["name", "score"])  # [] for read-only
# Access: editor.value returns the edited data in the same shape as the input
```

## Composite Inputs

### form

Wrap any element to gate submission.

```python
# Simple form
form = mo.ui.slider(0, 100).form()

# With options
form = mo.ui.text().form(
    submit_button_label="Save",
    show_clear_button=True,
    clear_on_submit=True,
    bordered=True
)

# Form with validation
form = mo.ui.text().form(
    validate=lambda value: "Required" if not value else None
)
```

### batch

Combine multiple elements.

```python
batch = mo.md("""
Name: {name}
Age: {age}
""").batch(
    name=mo.ui.text(),
    age=mo.ui.number(0, 120)
)
# Access: batch.value returns {"name": ..., "age": ...}
```

### array

Dynamic list of elements.

```python
array = mo.ui.array([mo.ui.text() for _ in range(3)])
# Access: array.value returns list of values
```

### dictionary

Dictionary of elements.

```python
dictionary = mo.ui.dictionary({
    "name": mo.ui.text(),
    "age": mo.ui.number(0, 120)
})
# Access: dictionary.value returns dict of values
```

## Navigation

### tabs

Tabbed interface with state tracking.

```python
tabs = mo.ui.tabs({
    "Tab 1": content1,
    "Tab 2": content2,
    "Tab 3": content3
})
tabs = mo.ui.tabs(
    {"Tab 1": content1, "Tab 2": expensive_content},
    value="Tab 2",            # Initially selected tab
    lazy=True,                # Render tab content only when opened
    orientation="vertical"
)
# Access: tabs.value returns selected tab name
```

### nav_menu

Navigation menu of links. Lives at `mo.nav_menu` (not `mo.ui`) and has no value.

```python
nav = mo.nav_menu({
    "/": "Home",               # Keys are hrefs, values are labels
    "/about": "About",
    "Dropdown": {              # A nested dict makes a submenu
        "/item1": "Item 1",
        "/item2": {"label": "Item 2", "description": "Second item"}
    }
}, orientation="horizontal")
```

## Chat

### chat

AI chat interface.

```python
chat = mo.ui.chat(
    model,  # Function that takes messages and returns response
    prompts=["Summarize this", "Explain in detail"],
    show_configuration_controls=True,
    allow_attachments=["image/png", "image/jpeg"],  # or True for any type
    max_height=500
)

# With custom model function
def my_model(messages, config):
    # messages: list of mo.ai.ChatMessage with .role and .content
    return "Response text"  # Any object: text, a chart, a UI element

chat = mo.ui.chat(my_model)

# Streaming: sync or async generators; each yield updates the UI
async def my_streaming_model(messages, config):
    async for chunk in stream(messages):
        yield chunk

# Built-in models: mo.ai.llm.openai, anthropic, google, groq, bedrock, pydantic_ai
chat = mo.ui.chat(mo.ai.llm.openai("gpt-5", system_message="You are helpful."))
# Access: chat.value returns the message history
```

## Custom Elements

### anywidget

Wrap an [anywidget](https://anywidget.dev/) to make it a reactive marimo element.

```python
from drawdata import ScatterWidget

widget = mo.ui.anywidget(ScatterWidget())
# Access: widget.value returns the widget's synced traits as a dict
# Widget attributes are proxied too, e.g. widget.data
```
