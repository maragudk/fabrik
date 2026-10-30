# Status API Reference

Display progress indicators, loading states, and toast notifications.

## Progress Bar

### mo.status.progress_bar

Show progress while iterating over collections.

```python
import marimo as mo

# Basic usage with iterable
for item in mo.status.progress_bar(items):
    process(item)

# With range
for i in mo.status.progress_bar(range(100)):
    do_work(i)

# With title
for item in mo.status.progress_bar(items, title="Processing"):
    process(item)
```

Full options:

```python
for item in mo.status.progress_bar(
    collection,
    title="Processing files",
    subtitle="Please wait...",
    completion_title="Complete!",
    completion_subtitle="All files processed",
    total=None,              # Required for iterators/generators without __len__ (TypeError otherwise)
    show_rate=True,          # Show items/second
    show_eta=True,           # Show estimated time remaining
    remove_on_exit=False,    # Keep bar visible after completion
    disabled=False           # Disable progress bar
):
    process(item)
```

### Context Manager Usage

For manual progress updates (`total` is required here):

```python
with mo.status.progress_bar(total=100) as bar:
    for i in range(100):
        do_work(i)
        bar.update()  # Increment by 1

# Custom increment
with mo.status.progress_bar(total=1000) as bar:
    for batch in batches:
        process_batch(batch)
        bar.update(increment=len(batch))

# update() also accepts title and subtitle
bar.update(title="Uploading", subtitle=f"{name} done")
```

Numeric progress updates are rate limited to once every 150ms; title and subtitle changes appear immediately.

### With Iterators

For iterators without `__len__`, specify `total`:

```python
def generate_items():
    for i in range(100):
        yield i

# Must specify total for generators
for item in mo.status.progress_bar(generate_items(), total=100):
    process(item)
```

### Nested Progress Bars

```python
for file in mo.status.progress_bar(files, title="Files"):
    chunks = list(read_chunks(file))  # Or pass total= for a generator
    for chunk in mo.status.progress_bar(chunks, title="Chunks", remove_on_exit=True):
        process(chunk)
```

## Spinner

### mo.status.spinner

Show loading spinner for indeterminate operations.

```python
# Basic usage
with mo.status.spinner():
    result = long_running_operation()

# With title
with mo.status.spinner(title="Loading data..."):
    data = fetch_data()

# Full options
with mo.status.spinner(
    title="Processing",
    subtitle="This may take a while",
    remove_on_exit=True  # Remove spinner when done (default)
) as spinner:
    for step in steps:
        spinner.update(subtitle=f"Step {step}")
        process(step)
```

### Updating Spinner

```python
with mo.status.spinner(title="Working") as spinner:
    spinner.update(title="Step 1")
    do_step1()

    spinner.update(title="Step 2")
    do_step2()

    spinner.update(title="Step 3", subtitle="Almost done...")
    do_step3()
```

## Combining with Outputs

Progress indicators work with `mo.output.append()`:

```python
with mo.status.progress_bar(items) as bar:
    for item in items:
        result = process(item)
        mo.output.append(f"Processed: {item.name}")
        bar.update()
```

## Async Support

Both progress bar and spinner work with async code. Async iterables need `async for` (and a `total`):

```python
async def process_async():
    with mo.status.spinner(title="Fetching"):
        data = await fetch_async()

    for item in mo.status.progress_bar(data):
        await process_item_async(item)

    async for event in mo.status.progress_bar(stream_events(), total=100):
        handle(event)
```

## Toast

### mo.status.toast

Show a brief notification in the corner of the screen.

```python
mo.status.toast("Saved", "Your changes were written to disk")

# Error toast; description can include HTML
mo.status.toast("Upload failed", "Check your connection", kind="danger")
```

## Best Practices

### Use Progress Bar for Known Iterations

```python
# Good - known total
for i in mo.status.progress_bar(range(100)):
    process(i)

# Good - list with known length
for item in mo.status.progress_bar(items):
    process(item)
```

### Use Spinner for Unknown Duration

```python
# Good - duration unknown
with mo.status.spinner(title="Connecting to server"):
    connection = establish_connection()
```

### Provide Informative Messages

```python
# Informative
with mo.status.spinner(title="Loading model", subtitle="model.pkl (2.3 GB)"):
    model = load_model()

# Not helpful
with mo.status.spinner():  # What's happening?
    model = load_model()
```

### Remove on Completion

```python
# Keep progress bar visible (for logging)
for item in mo.status.progress_bar(items, remove_on_exit=False):
    process(item)

# Remove spinner (cleaner UI)
with mo.status.spinner(remove_on_exit=True):
    data = load_data()
```

## Integration with Threading

```python
import marimo as mo

def worker():
    thread = mo.current_thread()
    with mo.status.progress_bar(range(100)) as bar:
        for i in range(100):
            if thread.should_exit:
                return
            do_work(i)
            bar.update()

thread = mo.Thread(target=worker)
thread.start()
```
