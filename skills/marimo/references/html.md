# HTML API Reference

Create, manipulate, and style HTML content.

## Core Functions

### mo.Html

Wrap HTML strings for display.

```python
import marimo as mo

# Create HTML element
element = mo.Html("<div>Hello, World!</div>")

# Display
element

# With complex HTML
element = mo.Html("""
<div class="card">
    <h3>Title</h3>
    <p>Content goes here.</p>
</div>
""")
```

`<script>` tags inside `mo.Html` and `mo.as_html` output are not executed; use `mo.iframe` for HTML that needs to run scripts.

### mo.as_html

Convert any Python object to HTML.

```python
# Convert matplotlib figure
import matplotlib.pyplot as plt
fig, ax = plt.subplots()
ax.plot([1, 2, 3])
html_fig = mo.as_html(fig)

# Convert DataFrame
html_df = mo.as_html(df)

# Embed in markdown
mo.md(f"Here's the chart: {mo.as_html(fig)}")
```

### mo.iframe

Wrap HTML in an isolated iframe.

```python
# Basic iframe
mo.iframe("<script>alert('isolated')</script>")

# With dimensions
mo.iframe(
    html_content,
    width="100%",   # Default: "100%"
    height="400px"  # Default: "400px"
)
```

Use iframes when:
- Running scripts (they don't execute in `mo.Html`)
- Isolating CSS styles from the rest of the page

`mo.iframe` takes an HTML string, not a URL, and is not a security sandbox (no `sandbox` attribute; it is served from the notebook's origin).

## Html Methods

### Styling

```python
element = mo.Html("<div>Content</div>")

# Apply CSS styles
styled = element.style({
    "color": "blue",
    "font-size": "18px",
    "padding": "10px",
    "border": "1px solid gray",
    "border-radius": "4px"
})

# Using keyword arguments (underscores become hyphens)
styled = element.style(
    color="blue",
    font_size="18px",    # Becomes font-size
    background_color="#f0f0f0"
)
```

### Alignment

```python
element = mo.Html("<div>Content</div>")

# Center, left, or right align
element.center()
element.left()
element.right()

# Or use standalone functions
mo.center(element)
mo.left(element)
mo.right(element)
```

### Callout

Wrap in emphasized container.

```python
element = mo.Html("<p>Important message</p>")

# Default (neutral)
element.callout()

# With kind
element.callout(kind="info")     # Blue
element.callout(kind="success")  # Green
element.callout(kind="warn")     # Yellow
element.callout(kind="danger")   # Red
element.callout(kind="neutral")  # Gray

# With a bold title line
element.callout(kind="warn", title="Warning")
```

### Batch

Create templated UI with multiple elements.

```python
template = mo.Html("""
<div>
    <label>Name: {name}</label>
    <label>Age: {age}</label>
</div>
""")

batch = template.batch(
    name=mo.ui.text(),
    age=mo.ui.number(0, 120)
)

# Access values
batch.value  # {"name": "...", "age": ...}
```

## Combining Elements

### String Interpolation

```python
# Embed Html in Html using f-strings
header = mo.Html("<h1>Dashboard</h1>")
content = mo.Html("<p>Welcome!</p>")

page = mo.Html(f"""
<div>
    {header}
    {content}
</div>
""")
```

### With Markdown

```python
html_element = mo.Html("<span style='color:red'>highlighted</span>")

mo.md(f"This text has {html_element} content.")
```

## Custom Components

### Creating Reusable Components

```python
def card(title, content, kind="neutral"):
    return mo.Html(f"""
    <div style="
        padding: 16px;
        border-radius: 8px;
        border: 1px solid #ddd;
        margin: 8px 0;
    ">
        <h3 style="margin: 0 0 8px 0">{title}</h3>
        <div>{content}</div>
    </div>
    """).callout(kind=kind)

# Usage
card("Welcome", "Hello, user!", kind="info")
```

### Interactive Components with Batch

```python
def labeled_input(label, input_element):
    return mo.Html(f"""
    <div style="margin: 8px 0">
        <label style="font-weight: bold">{label}</label>
        <div>{"{input}"}</div>
    </div>
    """).batch(input=input_element)

# Usage
name_input = labeled_input("Name:", mo.ui.text())
name_input.value  # {"input": "..."}
```

## Working with DataFrames

```python
# Convert DataFrame to HTML table
html_table = mo.as_html(df)

# Style the table
styled_table = html_table.style(
    max_height="400px",
    overflow="auto"
)

# Or use mo.ui.table for interactivity
interactive_table = mo.ui.table(df)
```

## Raw HTML in Markdown

```python
mo.md("""
# Report

<div style="display: flex; gap: 16px;">
    <div style="flex: 1; background: #f0f0f0; padding: 16px;">
        Column 1
    </div>
    <div style="flex: 1; background: #e0e0e0; padding: 16px;">
        Column 2
    </div>
</div>
""")
```

## Best Practices

### Prefer marimo Components

```python
# Use marimo's built-in components when available
mo.callout("Message", kind="info")  # Better than custom HTML

mo.hstack([a, b])  # Better than flex div

mo.ui.table(df)  # Better than HTML table
```

### Escape User Content

```python
import html

user_input = "<script>alert('xss')</script>"
safe_content = html.escape(user_input)

mo.Html(f"<div>{safe_content}</div>")
```

### Don't Treat Iframes as a Sandbox

```python
# mo.iframe isolates styles and lets scripts run, but those scripts share
# the notebook's origin. Escape or sanitize untrusted HTML instead.
mo.iframe(trusted_html_with_scripts)
```

### Keep Styles Inline

```python
# Inline styles work reliably
mo.Html('<div style="color: blue">Text</div>')

# External CSS may not apply as expected
```
