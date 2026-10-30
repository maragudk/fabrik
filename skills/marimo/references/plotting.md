# Plotting API Reference

marimo integrates with major plotting libraries and provides reactive chart components for interactive data selection.

## Supported Libraries

marimo renders output from these libraries automatically:
- Matplotlib
- Plotly
- Altair
- Seaborn
- Bokeh
- HoloViews
- hvPlot
- Leafmap
- Pygwalker

Simply return a figure/chart as the last expression in a cell. For matplotlib, return the `Axes` or `Figure`; `plt.show()` sends the plot to the console area instead.

Plots keep their library default themes in both light and dark notebooks.

## Reactive Charts

Interactive charts that return selected data. Supported for matplotlib, Altair, and Plotly.

### Matplotlib Charts

```python
import marimo as mo
import matplotlib.pyplot as plt
import numpy as np

x = np.random.randn(500)
y = np.random.randn(500)
plt.scatter(x, y)

# Wrap the Axes to make it reactive
ax = mo.ui.matplotlib(plt.gca())
ax

# In another cell - filter with the selection
mask = ax.value.get_mask(x, y)
selected_x, selected_y = x[mask], y[mask]
```

Selection modes:
- **Box selection**: Click and drag
- **Lasso selection**: Hold `Shift` and drag

`ax.value` is an `EmptySelection` (falsy), `BoxSelection` (`x_min`, `x_max`, `y_min`, `y_max`), or `LassoSelection` (`vertices`). All have `get_mask(x, y)`, which returns an all-`False` array when nothing is selected.

Options:

```python
ax = mo.ui.matplotlib(
    plt.gca(),
    value={"x": (1, 3), "y": (2, 4)},  # Initial box selection, clamped to axes
    debounce=True,                     # Send selection on mouse-up only
)
```

Best suited for scatter plots. The full figure renders as a static image; selections map to the given axes' coordinates.

### Altair Charts

```python
import marimo as mo
import altair as alt

# Create reactive Altair chart
chart = mo.ui.altair_chart(
    alt.Chart(df).mark_point().encode(
        x="x:Q",
        y="y:Q",
        color="category:N"
    )
)

# Display chart
chart

# In another cell - access selected data
selected_df = chart.value  # Filtered DataFrame; empty when nothing is selected
chart.dataframe            # Unfiltered chart data
chart.selections           # Raw selection (intervals or points)
```

Options:

```python
chart = mo.ui.altair_chart(
    alt_chart,
    chart_selection="point",    # "point", "interval", True, False
    legend_selection=True,      # True, False, or list of legend fields
    label="Select data points",
    on_change=lambda df: ...,   # Callback on selection change
)

# Apply selection to external DataFrame
filtered = chart.apply_selection(other_df)
```

Selection types:
- **Point selection**: Click individual points
- **Interval selection**: Drag to select region
- **Legend selection**: Click legend items to filter

`chart_selection=True` (default) picks point or interval based on the mark type; both selection args are ignored if the chart already defines its own selection params.

Performance note: `mo.ui.altair_chart` enables marimo's `marimo_csv` data transformer, which handles 400,000+ rows. For plain Altair charts, enable it with `alt.data_transformers.enable("marimo_csv")`.

Charts that use Altair transforms (filter, aggregate, etc.) need `vegafusion[embed]>=1.4.0` installed for selections to work.

### Plotly Charts

```python
import marimo as mo
import plotly.express as px

fig = px.scatter(df, x="x", y="y", color="category")

# Create reactive Plotly chart
chart = mo.ui.plotly(fig)

# Display
chart

# Access selection data
chart.value      # Selected points as a list of dicts
chart.indices    # Selected point indices
chart.points     # Selected point data as dicts
chart.ranges     # Axis range selections, e.g. {"x": [min, max]}
```

Options:

```python
chart = mo.ui.plotly(
    fig,
    config={"displayModeBar": False},  # Passed to plotly.js
    renderer_name=None,                # Defaults to pio.renderers.default
    label="",
    on_change=None,
)
```

Selections work for scatter/scattergl, line, area, bar, box, violin, strip, histogram, funnel, funnelarea, waterfall, heatmap, treemap, and sunburst charts. Other Plotly charts render but are not selectable.

### Matplotlib Interactive

```python
import marimo as mo
import matplotlib.pyplot as plt

fig, ax = plt.subplots()
ax.plot(x, y)

# Create interactive viewer with pan/zoom
mo.mpl.interactive(fig)  # Accepts a Figure or Axes
```

Features:
- Pan and zoom
- Coordinate hover
- No reactive selection (use `mo.ui.matplotlib` for that)
- Falls back to a static PNG where unsupported (e.g. HTML export, SubFigures)

## Static Plots

### Matplotlib

```python
import matplotlib.pyplot as plt

fig, ax = plt.subplots()
ax.plot([1, 2, 3], [1, 4, 9])
ax.set_xlabel("X")
ax.set_ylabel("Y")
fig  # Display
```

### Seaborn

```python
import seaborn as sns

fig = sns.scatterplot(data=df, x="x", y="y", hue="category")
fig.figure  # Display
```

### Plotly (non-reactive)

```python
import plotly.express as px

fig = px.line(df, x="date", y="value")
fig  # Display
```

### Altair (non-reactive)

```python
import altair as alt

chart = alt.Chart(df).mark_bar().encode(
    x="category:N",
    y="count:Q"
)
chart  # Display
```

## Embedding Plots in Markdown

```python
import matplotlib.pyplot as plt

fig, ax = plt.subplots()
ax.plot([1, 2, 3], [1, 4, 9])

mo.md(f"""
## Analysis Results

{mo.as_html(fig)}

The plot shows a quadratic relationship.
""")
```

## Custom Selection Behavior

Disable automatic selections and use custom Altair selections:

```python
import altair as alt

# Create custom selection
brush = alt.selection_interval()

chart = alt.Chart(df).mark_point().encode(
    x="x:Q",
    y="y:Q",
    color=alt.condition(brush, "category:N", alt.value("lightgray"))
).add_params(brush)

# Wrap without automatic selection
mo.ui.altair_chart(
    chart,
    chart_selection=False,
    legend_selection=False
)
```

## Multiple Linked Charts

A brush only links charts in the same Vega-Lite spec, so concatenate them instead of placing them in separate outputs.

```python
# Brush selection shared between charts
brush = alt.selection_interval()

chart1 = alt.Chart(df).mark_point().encode(
    x="x:Q",
    y="y:Q"
).add_params(brush)

chart2 = alt.Chart(df).mark_bar().encode(
    x="category:N",
    y="count()"
).transform_filter(brush)

linked = mo.ui.altair_chart(chart1 | chart2)  # hconcat
linked
```

## Faceted Charts

```python
chart = alt.Chart(df).mark_point().encode(
    x="x:Q",
    y="y:Q"
).facet(
    column="category:N"
)

mo.ui.altair_chart(chart)
```

## Large Datasets

For large datasets, consider:

1. **Sampling**: Plot a representative sample
2. **Aggregation**: Use binning or grouping
3. **Canvas rendering**: Use Plotly with `render_mode="webgl"`
4. **Lazy loading**: Load data on demand

```python
# Plotly WebGL for large datasets
import plotly.express as px

fig = px.scatter(
    large_df,
    x="x", y="y",
    render_mode="webgl"  # GPU acceleration
)
```

## Reactive Plot Updates

Charts automatically update when dependent variables change:

```python
# Cell 1
n_points = mo.ui.slider(10, 1000, value=100, label="Points")

# Cell 2
import numpy as np

x = np.random.randn(n_points.value)
y = np.random.randn(n_points.value)

# Cell 3
import matplotlib.pyplot as plt

fig, ax = plt.subplots()
ax.scatter(x, y, alpha=0.5)
ax.set_title(f"{n_points.value} Points")
fig  # Updates when slider changes
```
