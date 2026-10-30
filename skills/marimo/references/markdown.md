# Markdown API Reference

Render rich text with markdown, including embedded Python values, LaTeX, and icons.

## Basic Usage

### mo.md

Render markdown as HTML.

```python
import marimo as mo

# Basic markdown
mo.md("# Heading")
mo.md("**Bold** and *italic*")
mo.md("""
## Section

- Item 1
- Item 2
- Item 3
""")
```

## String Interpolation

Embed Python values using f-strings.

```python
name = "World"
count = 42

mo.md(f"Hello, **{name}**! Count: {count}")

# Embed calculations
mo.md(f"Result: {2 + 2}")

# Embed formatted values
price = 19.99
mo.md(f"Price: ${price:.2f}")
```

## Embedding UI Elements

Embed interactive elements directly in markdown.

```python
slider = mo.ui.slider(0, 100, label="Value")
checkbox = mo.ui.checkbox(label="Enable")

mo.md(f"""
## Settings

Adjust the value: {slider}

Toggle option: {checkbox}
""")
```

## Embedding Visualizations

Use `mo.as_html()` to embed non-HTML objects.

```python
import matplotlib.pyplot as plt

fig, ax = plt.subplots()
ax.plot([1, 2, 3], [1, 4, 9])

mo.md(f"""
## Analysis

Here's the chart:

{mo.as_html(fig)}

The data shows a quadratic relationship.
""")
```

## LaTeX Math

Render mathematical notation.

```python
# Inline math with single $
mo.md(r"The equation $E = mc^2$ is famous.")

# Display math with double $$
mo.md(r"""
The quadratic formula:

$$x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$
""")

# Alternative display math syntax
mo.md(r"""
\[
\int_0^\infty e^{-x^2} dx = \frac{\sqrt{\pi}}{2}
\]
""")
```

Use raw strings (prefix `r`) to avoid escaping backslashes.

### LaTeX Macros

Load custom LaTeX definitions.

```python
# From file
mo.latex(filename="macros.tex")

# From URL
mo.latex(filename="https://example.com/macros.tex")

# Define inline
mo.latex(r"""
\newcommand{\R}{\mathbb{R}}
\newcommand{\norm}[1]{\left\| #1 \right\|}
""")

# Then use in markdown
mo.md(r"Let $f: \R \to \R$ with $\norm{f} = 1$")
```

`mo.latex()` registers macros as a side effect, so call it in the same cell as `import marimo`; otherwise the macros may not be loaded before cells that use them. Pass either `text` or `filename`, not both.

## Icons

Embed icons from the Iconify library.

```python
# Shorthand inside markdown (no size/color/rotation options)
mo.md("::lucide:rocket:: Launch")

# Basic icon
mo.icon("lucide:heart")

# With options
mo.icon(
    "lucide:settings",
    size=24,                # Pixels
    color="blue",
    flip="horizontal",      # "horizontal", "vertical", "horizontal,vertical"
    rotate="90deg",         # "90deg", "180deg", "270deg"
    inline=True,            # False renders as a block element
    style={"opacity": 0.5}, # Extra CSS
)

# In markdown
mo.md(f"Click {mo.icon('lucide:arrow-right')} to continue")
```

Browse icons at [Iconify](https://icon-sets.iconify.design/). Icons load lazily from a CDN, so they do not render offline.

## Tables in Markdown

```python
mo.md("""
| Column 1 | Column 2 | Column 3 |
|----------|----------|----------|
| A        | B        | C        |
| D        | E        | F        |
""")
```

For interactive tables, use `mo.ui.table()` instead.

## Code Blocks

````python
mo.md("""
```python
def hello():
    print("Hello, World!")
```
""")
````

For editable code, use `mo.ui.code_editor()`.

## Links and Images

```python
mo.md("""
[Link text](https://example.com)

![Alt text](public/image.png)

<img src="public/image.png" width="400">
""")
```

Local files are served only from a `public/` folder next to the notebook, referenced with the `public/` prefix. Symlinks and `../` traversal are blocked.

## Details and Admonitions

Block syntax for collapsible sections and callouts inside markdown.

```python
mo.md("""
/// details | Heads up

Here's some additional context.
///

/// attention | This is important.

Pay attention to this text!
///
""")
```

For a programmatic alternative, use `mo.callout()`.

## Tooltips

Add interactive tooltips using data attributes.

```python
mo.md("""
Hover over <span data-tooltip="This is a tooltip">this text</span> to see more.
""")
```

## HTML in Markdown

Embed raw HTML when needed.

```python
mo.md("""
<div style="background: #f0f0f0; padding: 20px; border-radius: 8px;">
    <h3>Custom Box</h3>
    <p>Content with custom styling.</p>
</div>
""")
```

## Combining with Layouts

```python
mo.vstack([
    mo.md("# Dashboard"),
    mo.hstack([
        mo.md(f"**Users:** {user_count}"),
        mo.md(f"**Revenue:** ${revenue:,.2f}")
    ]),
    mo.md(f"""
    ## Details

    The current metrics show {mo.icon('lucide:trending-up')} growth.

    Adjust parameters: {slider}
    """)
])
```

## Best Practices

1. **Use raw strings for LaTeX**: `r"$\frac{1}{2}$"` avoids escape issues
2. **Embed UI elements for interactivity**: Prefer `{slider}` over separate cells
3. **Use mo.as_html() for plots**: Convert matplotlib/other plots before embedding
4. **Keep markdown cells focused**: Split long content into multiple cells for better reactivity
5. **Use callouts for emphasis**: `mo.callout(mo.md("..."), kind="info")`
