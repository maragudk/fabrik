# Layouts API Reference

Layout components organize and display content in marimo notebooks and apps.

## Stacking

### hstack / vstack

Arrange elements horizontally or vertically.

```python
import marimo as mo

# Horizontal stack
mo.hstack([element1, element2, element3])

# With options
mo.hstack(
    [element1, element2],
    justify="space-between",  # Default. "start", "center", "end", "space-between", "space-around"
    align="center",           # "start", "center", "end", "stretch" (default None)
    gap=2,                    # Spacing in rem (default 0.5)
    wrap=True,                # Wrap to next line if needed (default False)
    widths=[1, 2],            # Relative widths, or "equal" (default None)
)

# Vertical stack (justify defaults to "start"; heights works like widths)
mo.vstack([element1, element2, element3], gap=1, heights="equal")

# Nested stacks
mo.hstack([
    mo.vstack([a, b]),
    mo.vstack([c, d])
])
```

## Alignment

### center / left / right

Position content horizontally.

```python
mo.center(element)
mo.left(element)
mo.right(element)

# Can also use Html methods
element.center()
element.left()
element.right()
```

## Containers

### accordion

Collapsible sections.

```python
mo.accordion({
    "Section 1": content1,
    "Section 2": content2,
    "Section 3": content3
})

# With options
mo.accordion(
    {"Section 1": content1, "Section 2": content2},
    multiple=True,    # Allow multiple open sections
    lazy=True,        # Render content only when opened
    expanded=True,    # Initially open: True (first, or all if multiple), or a list of names
)
```

### tabs

Tabbed content (stateful - tracks selected tab).

```python
tabs = mo.ui.tabs({
    "Overview": overview_content,
    "Details": details_content,
    "Settings": settings_content
})

# Access selected tab
selected = tabs.value

# Options: initial tab, lazy-load tab content, vertical tabs
mo.ui.tabs(tabs_dict, value="Details", lazy=True, orientation="vertical")
```

### callout

Highlighted content box.

```python
mo.callout("Important information here", kind="info")

# Kinds: "info", "warn", "danger", "success", "neutral" (default)
mo.callout(content, kind="danger")
mo.callout(content, kind="success", title="Done")  # Optional bold title line

# Can also use Html method
element.callout(kind="warn", title="Warning")
```

### carousel

Slideshow of content.

```python
mo.carousel([slide1, slide2, slide3])
```

### sidebar

Side panel content.

```python
mo.sidebar([
    mo.md("# Navigation"),
    nav_menu,
    filters
])

# With a footer pinned to the bottom and a custom width
mo.sidebar(content, footer=mo.md("v1.0"), width="300px")

# Sidebar content appears alongside main notebook content.
# It must be the last expression in its cell.
```

## Navigation

### routes

Multi-page navigation. Values are objects or (sync/async) functions returning content; functions are only called when their route is active.

```python
mo.routes({
    "#/": render_home,
    "#/about": render_about,
    mo.routes.CATCH_ALL: render_home,
})
```

Use hash-based routes (`#/...`) for a single-page app; use path-based routes (`/...`) for multi-page apps served with `mo.create_asgi_app`. Nested and dynamic routes (e.g. `#/user/:id`) are not supported.

### nav_menu

Navigation menu of links. Keys are URLs (or a submenu label), values are labels (markdown).

```python
nav = mo.nav_menu({
    "#/": "Home",
    "Products": {  # Submenu, one level deep
        "#/products/a": "Category A",
        "#/products/b": {"label": "Category B", "description": "More products"},
    },
    "#/contact": f"{mo.icon('lucide:phone')} Contact",
}, orientation="horizontal")  # or "vertical" (e.g. inside mo.sidebar)
```

### outline

Table of contents from markdown headers.

```python
mo.outline()  # Auto-generates from notebook headings
mo.outline(label="Table of Contents")
```

## Data Display

### tree

Hierarchical data display.

```python
mo.tree({
    "Root": {
        "Child 1": {
            "Grandchild": "value"
        },
        "Child 2": ["item1", "item2"]
    }
})

# From nested dict/list/tuple, with optional label
mo.tree(nested_data, label="Config")
```

### json

JSON viewer with syntax highlighting.

```python
mo.json(data)

# Accepts a JSON string or JSON-compatible object, with optional label
mo.json(data, label="config")
```

### stat

Statistics card.

```python
mo.stat(
    value="$1,234",
    label="Revenue",
    caption="vs last month",
    direction="increase",  # "increase", "decrease", None
    bordered=True,         # Default False
    target_direction="increase",  # Which direction is good (colors the arrow); default "increase"
)

# Multiple stats
mo.hstack([
    mo.stat("150", "Users", direction="increase"),
    mo.stat("$5K", "Revenue", direction="increase"),
    mo.stat("3.2%", "Bounce Rate", direction="decrease", target_direction="decrease")
])
```

## Performance

### lazy

Defer content rendering until visible.

```python
mo.lazy(expensive_content)

# Useful for large outputs or expensive computations
mo.lazy(lambda: generate_large_chart())  # Function (sync or async) runs when visible

# Typical use: inside tabs or accordions
mo.ui.tabs({"Overview": summary, "Charts": mo.lazy(expensive_chart, show_loading_indicator=True)})
```

### plain

Display a value without marimo's opinionated formatting.

```python
mo.plain(df)

# Best way to opt out of marimo's default rich dataframe rendering
```

## Grid and Slides Layouts (App Mode)

In addition to the default vertical layout, apps can use a grid or slides layout, chosen in the editor:

1. Open the app preview (button in the bottom-right of the editor, or the command palette)
2. Pick "Grid" or "Slides" from the layout dropdown
3. Grid: drag and drop cell outputs onto the grid and resize them. Slides: reorder slides, set slide types, and add speaker notes (reveal.js)

Layout metadata saves to a `layouts/` folder next to the notebook; include it in version control and deployments.

## Combining Layouts

```python
# Complex layout example
mo.vstack([
    mo.md("# Dashboard"),
    mo.hstack([
        mo.stat("100", "Total"),
        mo.stat("50", "Active"),
        mo.stat("25", "New")
    ]),
    mo.accordion({
        "Filters": mo.vstack([filter1, filter2]),
        "Settings": settings_panel
    }),
    mo.ui.tabs({
        "Chart": chart,
        "Table": table,
        "Raw Data": mo.json(data)
    })
])
```
