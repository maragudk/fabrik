# Watch API Reference

Reactive file system monitoring that triggers cell re-execution on changes.

## File Watching

### mo.watch.file

Watch a file for content changes.

```python
import marimo as mo

# Watch a file
config_file = mo.watch.file("config.json")

# Read content (cell re-runs when file changes)
content = config_file.read_text()
```

Returns a `FileState` that wraps `pathlib.Path`: `read_text()`, `read_bytes()`, `write_text()`, `write_bytes()`, `exists()`, and most other `Path` attributes work; `open()`, `rename()`, `replace()` are not available. The file does not need to exist yet (deletion and creation both trigger a re-run). Passing a directory raises `ValueError`.

### mo.watch.directory

Watch a directory for structural changes (files added/removed).

```python
data_dir = mo.watch.directory("./data")

# List files (re-runs when directory changes)
files = list(data_dir.glob("*.csv"))
```

Returns a `DirectoryState` with `iterdir()`, `glob()`, `rglob()`, `walk()`, and `exists()`; file read/write methods are not available. The path must be an existing directory.

**Note**: Directory watching does NOT react to file content changes, only to files or folders being added or removed. It does not follow symlinks.

## Common Patterns

```python
# Auto-reload config
config_file = mo.watch.file("config.yaml")
config = yaml.safe_load(config_file.read_text())

# Watch for new data files
data_dir = mo.watch.directory("./input")
for csv in data_dir.glob("*.csv"):
    process(csv)
```

## Caveats

- Use watchers for reading; writing to a watched file re-triggers its dependents and can cause loops
- Watchers poll about once per second (file mtime, directory tree)
- Directory watching is recursive: it covers the whole subtree, so watching a huge tree is costly
- Reactivity only applies in a running notebook (`marimo edit`/`run`); as a script, cells run once and the wrapper just reads the path
- In WASM, files can be read and written but external changes don't trigger re-runs
