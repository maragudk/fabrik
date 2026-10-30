---
name: marimo
description: Guide for creating and working with marimo notebooks, the reactive Python notebook that stores as pure .py files. This skill should be used when creating, editing, running, or deploying marimo notebooks.
license: MIT
---

# marimo

## Overview

marimo is an open-source reactive Python notebook that reinvents notebooks as reproducible, interactive, and shareable Python programs. Unlike traditional Jupyter notebooks, marimo notebooks:

- Store as pure `.py` files (Git-friendly, no JSON)
- Execute reactively (like a spreadsheet)
- Run as scripts or deploy as web apps
- Prevent bugs through automatic dependency tracking

## Installation

```bash
uv add marimo                         # In a uv project (or: pip install marimo)
uv add "marimo[recommended]"          # With extras (SQL cells, AI, plotting helpers)
uv add "marimo[sql]"                  # With SQL support

uvx marimo edit --sandbox notebook.py # Standalone notebook, no project needed
marimo tutorial intro                 # Start tutorial
```

## CLI Commands

```bash
# Edit
marimo edit                           # Home page: browse and create notebooks
marimo edit notebook.py               # Edit existing (or create)
marimo edit --watch notebook.py       # Reload when the file changes on disk
marimo edit --sandbox notebook.py     # Isolated env from PEP 723 inline deps (uv or pixi)

# Run as app
marimo run notebook.py                # Read-only app
marimo run notebook.py --watch        # Auto-reload on changes

# Run as script
python notebook.py

# Create
marimo new                            # Empty notebook
marimo new "analyze sales data"       # Generate from a prompt with AI

# Lint and format
marimo check notebook.py              # Report issues (multiple definitions, cycles, ...)
marimo check --fix notebook.py        # Fix what is fixable, in place

# Convert to marimo (.ipynb, .md with python fences, py:percent scripts)
marimo convert notebook.ipynb -o notebook.py

# Export
marimo export html notebook.py -o output.html
marimo export html-wasm notebook.py -o out/ --mode run  # Browser-executable (Pyodide)
marimo export ipynb notebook.py -o notebook.ipynb
marimo export md notebook.py -o notebook.md
marimo export script notebook.py -o script.py           # Flat Python script
marimo export pdf notebook.py -o notebook.pdf
```

## Key Concepts

### Reactivity

Running a cell automatically runs all cells that depend on it. Execution order is determined by variable dependencies (DAG), not cell position.

### Cell Rules

1. Each global variable must be defined in exactly one cell
2. Variables prefixed with an underscore (`_tmp`) are local to their cell
3. Mutations like `list.append()` aren't tracked; reassign instead
4. If mutating is needed, do it in the same cell as the declaration
5. No cycles between cells, and no `import *`

### File Format

Notebooks are pure Python files with marimo decorators. Each cell is a function whose parameters are the variables it reads and whose return tuple is the variables it defines:

```python
import marimo

__generated_with = "0.25.2"
app = marimo.App(width="medium")

with app.setup:
    # Setup cell: runs first; its names are usable by top-level functions
    import marimo as mo
    import polars as pl


@app.function
def clean(df: pl.DataFrame) -> pl.DataFrame:
    # Top-level function: importable with `from notebook import clean`
    return df.drop_nulls()


@app.cell(hide_code=True)
def _():
    mo.md(r"""
    # My Notebook
    """)
    return


@app.cell
def _():
    df = clean(pl.read_csv("data.csv"))
    return (df,)


@app.cell
def _(df):
    df.describe()
    return


if __name__ == "__main__":
    app.run()
```

A setup cell and `@app.function` are optional; a plain notebook imports `marimo as mo` in a regular `@app.cell` and returns `(mo,)`. A cell that defines nothing ends with a bare `return`. The last expression in a cell is its output.

`@app.function` only works when the cell defines exactly one function that refers only to setup-cell names or other top-level definitions; `@app.class_definition` is the equivalent for classes. See `references/app.md` and `references/cell.md`.

### Working on Notebooks as an Agent

- Editing the `.py` file directly is fine: keep the format above, keep cell parameters and return tuples in sync with the variables each cell reads and defines, and run `marimo check` (or `uvx marimo check`) afterwards to catch multiple definitions, cycles, and formatting issues.
- If the user has the notebook open, they should run `marimo edit --watch notebook.py` so the editor picks up your changes.
- `marimo pair` connects an agent to a running notebook session to create, edit, and run cells live and read their outputs. Run `marimo pair --help` for the workflow. In that mode, edit through the pair API only, not the file.

## API Reference

Detailed documentation for each API is available in the `references/` directory. Consult these files for comprehensive examples and parameters.

### Core

| API | Reference File | Description |
|-----|----------------|-------------|
| Markdown | `references/markdown.md` | `mo.md()` for rich text, LaTeX, icons |
| HTML | `references/html.md` | `mo.Html`, `mo.as_html()`, styling |
| Outputs | `references/outputs.md` | `mo.output.append()`, console redirection |

### UI Elements

| API | Reference File | Description |
|-----|----------------|-------------|
| Inputs | `references/inputs.md` | Sliders, text, dropdowns, tables, forms, etc. |
| Layouts | `references/layouts.md` | `mo.hstack`, `mo.vstack`, tabs, accordion, etc. |
| Media | `references/media.md` | Images, audio, video, PDF, downloads |
| Plotting | `references/plotting.md` | Altair, Plotly, matplotlib integration |
| Diagrams | `references/diagrams.md` | Mermaid diagrams |
| Status | `references/status.md` | Progress bars, spinners |

### Data

| API | Reference File | Description |
|-----|----------------|-------------|
| SQL | `references/sql.md` | `mo.sql()` for database and DataFrame queries |

### Advanced

| API | Reference File | Description |
|-----|----------------|-------------|
| Control Flow | `references/control-flow.md` | `mo.stop()`, conditional execution |
| State | `references/state.md` | `mo.state()` for UI synchronization |
| Caching | `references/caching.md` | `@mo.cache`, `@mo.persistent_cache` |
| Query Params | `references/query-params.md` | `mo.query_params()` for URL state |
| CLI Args | `references/cli-args.md` | `mo.cli_args()` for script arguments |
| Watch | `references/watch.md` | `mo.watch.file()` for reactive file monitoring |
| App | `references/app.md` | Embedding notebooks, `mo.app_meta()` |
| Cell | `references/cell.md` | Cross-notebook execution, testing |

## Quick Examples

### Basic UI

```python
import marimo as mo

slider = mo.ui.slider(0, 100, value=50, label="Threshold")
slider

# In another cell
mo.md(f"Selected value: **{slider.value}**")
```

### Interactive Table

```python
table = mo.ui.table(df, selection="multi")
table

# In another cell
selected = table.value  # Selected rows as DataFrame
```

### SQL Query

```python
result = mo.sql(f"SELECT * FROM df WHERE value > {threshold.value}")
```

### Conditional Execution

```python
mo.stop(form.value is None, mo.md("Submit the form to continue"))
# Rest of cell runs only after form submission
```

## Running as Apps

```bash
marimo run notebook.py                         # Local app
marimo export html-wasm notebook.py -o out/    # Static WASM app
```

Layout options: Vertical (default), Grid (drag-drop in editor), Slides.

## Best Practices

- **Globals**: Keep global variables few and descriptive; use `_`-prefixed names or functions for intermediates
- **Reactivity**: Declare and mutate variables in the same cell, or create a new variable from the old one
- **Idempotence**: Write cells that produce the same output given the same inputs
- **Performance**: Use `@mo.cache` / `mo.persistent_cache` for expensive computations
- **UI Gating**: Use `mo.ui.run_button()` with `mo.stop()` to prevent expensive ops until ready
- **State**: Avoid `mo.state()` and `on_change` handlers; rely on reactive execution of UI elements
- **Modules**: Move long or complex logic into Python modules and import them
- **Organization**: Cell position doesn't matter; organize for readability

## Resources

- [Documentation](https://docs.marimo.io/)
- [GitHub](https://github.com/marimo-team/marimo)
- [Examples Gallery](https://marimo.io/gallery)
