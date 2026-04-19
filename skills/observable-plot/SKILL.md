---
name: observable-plot
description: Guide for using Observable Plot, a JavaScript library for exploratory data visualization built on D3. Use this skill when creating charts, exploring data, or building visualizations with marks, scales, and transforms.
license: MIT
---

# Observable Plot

Observable Plot is a JavaScript library for exploratory data visualization. It's built on D3 and provides a concise, declarative API for creating charts.

## Installation

```bash
npm install @observablehq/plot
```

Or via CDN:
```html
<script type="module">
import * as Plot from "https://cdn.jsdelivr.net/npm/@observablehq/plot@0.6/+esm";
</script>
```

## Core Concepts

### Plot.plot(options)

The main function that renders a visualization. Returns an SVG or HTML figure element.

```javascript
Plot.plot({
  marks: [
    Plot.dot(data, {x: "weight", y: "height"})
  ]
})
```

### Key Options

| Option | Description | Default |
|--------|-------------|---------|
| `width` | Outer width in pixels | 640 |
| `height` | Outer height in pixels | auto |
| `margin` | All margins | varies |
| `marginTop/Right/Bottom/Left` | Individual margins | varies |
| `marks` | Array of marks to render | required |
| `color` | Color scale options | auto |
| `x`, `y` | Position scale options | auto |
| `title`, `subtitle` | Chart titles | none |
| `caption` | Figure caption | none |

### Data Format

Plot expects tabular data as arrays of objects:

```javascript
const data = [
  {date: new Date("2024-01-01"), value: 100, category: "A"},
  {date: new Date("2024-01-02"), value: 120, category: "B"}
];
```

### Channel Mapping

Map data columns to visual properties:

```javascript
Plot.dot(data, {
  x: "date",        // column name
  y: "value",       // column name
  fill: "category", // color by category
  r: 5              // constant radius
})
```

## Quick Examples

### Line Chart
```javascript
Plot.lineY(data, {x: "date", y: "value"}).plot()
```

### Bar Chart
```javascript
Plot.barY(data, {x: "category", y: "value"}).plot()
```

### Scatter Plot
```javascript
Plot.dot(data, {x: "weight", y: "height", fill: "species"}).plot()
```

### Histogram
```javascript
Plot.rectY(data, Plot.binX({y: "count"}, {x: "value"})).plot()
```

### Area Chart
```javascript
Plot.areaY(data, {x: "date", y: "value", fill: "steelblue"}).plot()
```

## Documentation Files

This skill includes detailed documentation for each feature:

### Marks (Visual Elements)
- `marks/area.md` - Area charts and stacked areas
- `marks/bar.md` - Bar charts (horizontal and vertical)
- `marks/dot.md` - Scatter plots and bubble charts
- `marks/line.md` - Line charts
- `marks/rect.md` - Rectangles, histograms, heatmaps
- `marks/text.md` - Text labels and annotations
- `marks/rule.md` - Reference lines
- `marks/cell.md` - Heatmaps with ordinal dimensions
- `marks/tip.md` - Interactive tooltips
- `marks/axis.md` - Custom axes
- `marks/geo.md` - Geographic/map visualizations
- `marks/link.md` - Connections between points
- `marks/arrow.md` - Directed arrows
- `marks/vector.md` - Vector fields
- `marks/tick.md` - Tick marks
- `marks/box.md` - Box plots
- `marks/frame.md` - Frame decoration
- `marks/image.md` - Image glyphs
- `marks/contour.md` - Contour plots
- `marks/density.md` - Density estimation
- `marks/raster.md` - Raster/heatmap images
- `marks/hexgrid.md` - Hexagonal grids
- `marks/waffle.md` - Waffle charts
- `marks/delaunay.md` - Voronoi and Delaunay
- `marks/bollinger.md` - Bollinger bands
- `marks/difference.md` - Difference charts
- `marks/tree.md` - Hierarchical trees
- `marks/auto.md` - Automatic mark selection
- `marks/linear-regression.md` - Trend lines
- `marks/crosshair.md` - Interactive crosshairs
- `marks/grid.md` - Grid lines

### Transforms (Data Processing)
- `transforms/bin.md` - Binning for histograms
- `transforms/group.md` - Grouping categorical data
- `transforms/stack.md` - Stacking for area/bar charts
- `transforms/dodge.md` - Beeswarm plots
- `transforms/hexbin.md` - Hexagonal binning
- `transforms/window.md` - Moving averages
- `transforms/select.md` - Selecting specific points
- `transforms/normalize.md` - Normalizing values

### Features
- `features/scales.md` - Scale configuration
- `features/facets.md` - Small multiples
- `features/projections.md` - Map projections
- `features/legends.md` - Legend configuration
- `features/interactions.md` - Interactive features
- `features/curves.md` - Line interpolation
- `features/markers.md` - Line markers
- `features/shorthand.md` - Concise syntax
- `features/intervals.md` - Time intervals

## Common Patterns

### Adding a Grid
```javascript
Plot.plot({
  y: {grid: true},
  marks: [Plot.line(data, {x: "date", y: "value"})]
})
```

### Color Legend
```javascript
Plot.plot({
  color: {legend: true},
  marks: [Plot.dot(data, {x: "x", y: "y", fill: "category"})]
})
```

### Faceting (Small Multiples)
```javascript
Plot.plot({
  facet: {data, x: "region"},
  marks: [Plot.dot(data, {x: "income", y: "lifeExpectancy"})]
})
```

### Interactive Tooltips
```javascript
Plot.plot({
  marks: [
    Plot.dot(data, {x: "x", y: "y", tip: true})
  ]
})
```

### Stacked Area Chart
```javascript
Plot.plot({
  marks: [
    Plot.areaY(data, {x: "date", y: "value", fill: "category"})
  ]
})
```

## Framework Integration

### React
```jsx
import * as Plot from "@observablehq/plot";
import { useRef, useEffect } from "react";

function Chart({ data }) {
  const ref = useRef();
  useEffect(() => {
    const plot = Plot.plot({
      marks: [Plot.dot(data, {x: "x", y: "y"})]
    });
    ref.current.append(plot);
    return () => plot.remove();
  }, [data]);
  return <div ref={ref} />;
}
```

### Vanilla JS
```javascript
const plot = Plot.plot({
  marks: [Plot.dot(data, {x: "x", y: "y"})]
});
document.body.append(plot);
```

## Resources

- [Official Documentation](https://observablehq.com/plot/)
- [Examples Gallery](https://observablehq.com/@observablehq/plot-gallery)
- [GitHub Repository](https://github.com/observablehq/plot)
