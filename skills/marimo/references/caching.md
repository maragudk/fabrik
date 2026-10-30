# Caching API Reference

Cache expensive computations in memory or on disk for better performance.

## Cache Decorators

### mo.cache

In-memory cache based on function arguments.

```python
import marimo as mo

@mo.cache
def expensive_computation(x, y):
    # Result cached based on (x, y)
    return complex_calculation(x, y)

# First call computes
result1 = expensive_computation(1, 2)

# Second call with same args returns cached result
result2 = expensive_computation(1, 2)  # Instant

# Different args compute fresh
result3 = expensive_computation(3, 4)
```

### mo.persistent_cache

Disk-based cache that persists across sessions.

```python
@mo.persistent_cache
def very_expensive(data_path):
    # Result saved to disk
    return load_and_process(data_path)

# First run: computes and saves to disk
result = very_expensive("data.csv")

# Subsequent runs (even after restart): loads from disk
result = very_expensive("data.csv")  # Instant
```

Options:

```python
@mo.persistent_cache(
    save_path="./cache",        # Custom cache directory
    method="pickle"             # "pickle" (default), "json", or "lazy"
)
def cached_function(x):
    return process(x)
```

### mo.lru_cache

Bounded memory cache (LRU eviction).

```python
@mo.lru_cache(maxsize=128)
def bounded_cache(x):
    return compute(x)

# Keeps most recent 128 unique argument combinations
# Evicts least recently used when full
# maxsize defaults to 128; maxsize=-1 disables the limit
```

## Cache Key Construction

Cache keys are built from:

1. **Function arguments**: Primitives, UI elements, arrays, pickleable objects
2. **Closed-over variables**: Variables referenced from outer scope
3. **Source code**: Used when variables can't be hashed/pickled

```python
threshold = 0.5  # Closed-over variable

@mo.cache
def filter_data(data):
    # Cache key includes: data + threshold + source code
    return data[data > threshold]

# Changing threshold invalidates cache
threshold = 0.7
filter_data(data)  # Recomputes
```

## Parameters

### Common Parameters

```python
@mo.cache(
    pin_modules=False  # If True, invalidate when module versions change
)
def func(x):
    return process(x)
```

### persistent_cache Parameters

```python
@mo.persistent_cache(
    save_path="./my_cache",  # Default: __marimo__/cache/ next to the notebook
    method="pickle",          # "pickle" (default), "json", or "lazy"
    pin_modules=False,
    name="my_cache"           # Identifier for context manager usage
)
def func(x):
    return process(x)
```

## Context Manager Usage

Use caching as context manager for blocks of code.

```python
with mo.persistent_cache(name="data_processing"):
    # Everything in this block is cached
    df = load_large_file("data.parquet")
    processed = transform(df)
    result = aggregate(processed)

# result is cached
```

`mo.cache("name")` and `mo.lru_cache("name")` work the same way as in-memory context managers:

```python
with mo.cache("embeddings"):
    X = embed(texts)
```

On a cache hit the whole block is skipped (including prints) and its variables are restored. The context manager uses `sys.settrace`, so it may conflict with debuggers.

## Async Support

All cache decorators support async functions.

```python
@mo.cache
async def fetch_data(url):
    async with aiohttp.ClientSession() as session:
        async with session.get(url) as response:
            return await response.json()

# Usage
data = await fetch_data("https://api.example.com/data")
```

Concurrent calls with the same arguments run the function once; the others await that result.

## Cache Behavior

### What Gets Cached

- Return values only
- Side effects are NOT cached (skipped on cache hit)

```python
@mo.cache
def with_side_effect(x):
    print("Computing...")  # Only prints on cache miss
    return x * 2

with_side_effect(5)  # Prints "Computing...", returns 10
with_side_effect(5)  # No print, returns 10 (cached)
```

### Cache Persistence

- `mo.cache`: Cleared when notebook restarts
- `mo.persistent_cache`: Persists across sessions (saved to disk)
- `mo.lru_cache`: Cleared when notebook restarts, bounded size
- All of them survive re-running the cell that defines the cached function, as long as that cell's code (and its ancestors' code) is unchanged. Unlike `functools.cache`, which resets on every re-run.

### Cache Invalidation

Caches invalidate when:
- Arguments change
- Closed-over variables change
- Source code changes (if variables can't be hashed)
- `pin_modules=True` and module versions change

Not tracked: the source code of imported (non-marimo) modules, and mutations of variables. Decorators from other modules that don't use `functools.wraps` can cause cache-key collisions between different functions when stacked under `@mo.cache`.

## Best Practices

### Isolate Cached Functions

Put cached functions in their own cells to prevent invalidation from unrelated changes.

```python
# Cell 1: Cached function (isolated)
@mo.cache
def process_data(df):
    return expensive_transform(df)

# Cell 2: Use the function
result = process_data(my_df)
```

### Use Closures for Unhashable Objects

```python
# Close over unhashable objects instead of passing as arguments
model = load_model()  # Unhashable

@mo.cache
def predict(input_data):
    # model is closed over, not an argument
    return model.predict(input_data)
```

### Return Serializable Values

For `mo.persistent_cache`, return values must be pickleable:

```python
@mo.persistent_cache
def good_cache(x):
    return {"result": compute(x)}  # Dict is pickleable

@mo.persistent_cache
def bad_cache(x):
    return lambda: x  # Lambda is NOT pickleable - will fail
```

### Cache at the Right Granularity

```python
# TOO GRANULAR - many small caches
@mo.cache
def step1(x): return x + 1

@mo.cache
def step2(x): return x * 2

# BETTER - cache the whole pipeline
@mo.cache
def pipeline(x):
    result = x + 1
    result = result * 2
    return result
```

### Watch Files Used Inside Caches

Read files through `mo.watch.file` so edits to the file invalidate the cache:

```python
# Cell 1
data_file = mo.watch.file("data.txt")
```

```python
# Cell 2
with mo.persistent_cache("parsed"):
    parsed = parse(data_file.read_text())
```

## Automatic Cell Caching (experimental)

Cache every cell, not just decorated functions, by enabling it in `pyproject.toml` or the notebook's PEP 723 metadata:

```toml
[tool.marimo.runtime]
cache_cells = true
```

On restart, cells with a cache hit are skipped and their variables restored. Cells whose values can't be restored re-run live (as do cells that define UI elements).

## Clearing Caches

```python
# Clear specific function's cache
expensive_computation.cache_clear()

# For persistent cache, delete the cache directory
import shutil
shutil.rmtree("__marimo__/cache")
```

Inspect on-disk caches from the CLI:

```bash
marimo cache dir notebook.py      # Print the cache directories for a notebook (or folder)
marimo cache size -r notebooks/   # Disk usage and entry counts, recursively
```

For git projects, add `**/__marimo__/cache/` to `.gitignore`.

## Debugging Cache

```python
@mo.cache
def my_func(x):
    print(f"Cache miss for x={x}")
    return x * 2

# Monitor cache hits/misses via print output

my_func.cache_info()
# CacheInfo(hits=1, misses=2, maxsize=None, currsize=2, time_saved=0.0)
```
