# Query Parameters API Reference

Access and manipulate URL query parameters in marimo apps.

## Overview

Query parameters allow:
- Passing data through URLs
- Persisting UI state in the URL
- Sharing specific app states via links
- Deep linking to filtered views

## Basic Usage

### mo.query_params

Get the query parameters object. Call it in its own cell; mutating it re-runs every other cell that references it.

```python
import marimo as mo

# Get query params (dict-like object)
params = mo.query_params()

# Read parameter
search = params.get("search", "")
page = params.get("page", "1")

# Check if parameter exists
if "filter" in params:
    apply_filter(params["filter"])
```

## Reading Parameters

```python
params = mo.query_params()

# Get with default
value = params.get("key", "default")

# Direct access (returns None if missing, no KeyError)
value = params["key"]

# Repeated keys (?tag=a&tag=b) give a list; get_all always returns a list
tags = params.get_all("tag")  # ["a", "b"], or [] if missing

# Get all as dict (values are str or list[str])
all_params = params.to_dict()

# Iterate (yields keys; there is no .items())
for key in params:
    print(f"{key}: {params[key]}")
```

## Setting Parameters

```python
params = mo.query_params()

# Set single parameter
params["search"] = "hello"

# Set using method
params.set("page", "2")

# Set a list (?tag=a&tag=b), or append to one
params["tag"] = ["a", "b"]
params.append("tag", "c")

# Set multiple (there is no .update())
for key, value in {"search": "hello", "page": "1", "sort": "date"}.items():
    params[key] = value

# Remove parameter
del params["filter"]          # KeyError if missing
params.remove("filter")       # no-op if missing
params.remove("tag", "a")     # remove one value from a list
params["filter"] = None       # setting None (or []) also removes the key

# Clear all
params.clear()
```

## Syncing UI with URL

### Text Input

```python
params = mo.query_params()

search = mo.ui.text(
    value=params.get("search", ""),
    placeholder="Search...",
    on_change=lambda v: params.set("search", v)
)
```

### Dropdown

```python
params = mo.query_params()

sort_options = ["date", "name", "size"]
sort = mo.ui.dropdown(
    options=sort_options,
    value=params.get("sort", "date"),
    on_change=lambda v: params.set("sort", v)
)
```

### Checkbox

```python
params = mo.query_params()

# Boolean as string
show_all = mo.ui.checkbox(
    label="Show all",
    value=params.get("show_all") == "true",
    on_change=lambda v: params.set("show_all", "true" if v else "false")
)
```

### Slider

```python
params = mo.query_params()

threshold = mo.ui.slider(
    0, 100,
    value=int(params.get("threshold", "50")),
    on_change=lambda v: params.set("threshold", str(v))
)
```

## Reactive Updates

Query params integrate with marimo's reactivity:

```python
# Cell 1
params = mo.query_params()

# Cell 2 - re-runs whenever another cell sets a param
search_term = params.get("search", "")
results = search_database(search_term)

# Cell 3 - display results
mo.ui.table(results)
```

## Validation with Pydantic

Use Pydantic for type-safe query parameters:

```python
from pydantic import BaseModel, Field, ValidationError

class FilterParams(BaseModel):
    search: str = ""
    page: int = Field(1, ge=1)
    per_page: int = Field(10, ge=1, le=100)
    sort: str = Field("date", pattern="^(date|name|size)$")

# Parse and validate
params = mo.query_params()
try:
    filters = FilterParams(**params.to_dict())
except ValidationError as e:
    mo.callout(f"Invalid parameters: {e}", kind="danger")
```

## URL Patterns

### Building Shareable URLs

```python
# Set parameters for sharing
params = mo.query_params()
params["view"] = "chart"
params["date_range"] = "2024-01-01,2024-12-31"
params["categories"] = "a,b,c"

# URL becomes: ?view=chart&date_range=2024-01-01,2024-12-31&categories=a,b,c
```

### Parsing Complex Values

```python
params = mo.query_params()

# Parse comma-separated list
categories = params.get("categories", "").split(",") if params.get("categories") else []

# Parse date range
date_range = params.get("date_range", "")
if date_range:
    start, end = date_range.split(",")
```

## Complete Example

```python
# Cell 1: Query params
params = mo.query_params()

# Cell 2: UI controls synced with URL
search = mo.ui.text(
    value=params.get("q", ""),
    placeholder="Search...",
    on_change=lambda v: params.set("q", v)
)

category = mo.ui.dropdown(
    ["All", "Electronics", "Books", "Clothing"],
    value=params.get("cat", "All"),
    on_change=lambda v: params.set("cat", v)
)

sort_by = mo.ui.radio(
    ["Relevance", "Price", "Rating"],
    value=params.get("sort", "Relevance"),
    on_change=lambda v: params.set("sort", v)
)

mo.vstack([search, category, sort_by])

# Cell 3: Filtered results
results = filter_products(
    query=search.value,
    category=None if category.value == "All" else category.value,
    sort=sort_by.value.lower()
)

mo.ui.table(results)
```

## Best Practices

### Use Meaningful Parameter Names

```python
# Good
params.set("search_query", value)
params.set("date_start", "2024-01-01")

# Less clear
params.set("q", value)
params.set("ds", "2024-01-01")
```

### Handle Missing Parameters

```python
# Always provide defaults
page = int(params.get("page", "1"))
search = params.get("search", "")
```

### Validate Before Using

```python
page = params.get("page", "1")
try:
    page_num = int(page)
    if page_num < 1:
        page_num = 1
except ValueError:
    page_num = 1
```

### Keep URLs Clean

```python
# Remove empty parameters
if not search.value:
    params.remove("search")
else:
    params.set("search", search.value)
```

## Limitations

- Query params are strings (or lists of strings for repeated keys); convert types manually
- Long URLs may hit browser limits
- Not suitable for sensitive data
- Changes trigger cell re-execution
