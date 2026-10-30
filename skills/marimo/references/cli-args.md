# CLI Arguments API Reference

Access command-line arguments when running notebooks as scripts.

## Overview

marimo notebooks can be run as Python scripts with command-line arguments:

```bash
python notebook.py --arg1 value1 --arg2 value2
```

With `marimo` commands (`edit`, `run`, `export`), put notebook arguments after a `--` separator so they aren't parsed as marimo options:

```bash
marimo edit notebook.py -- --arg1 value1 --arg2 value2
```

Don't use `--` with `python notebook.py`: it is passed through to `sys.argv`, so `argparse` treats everything after it as positional and `mo.cli_args()` gets a bogus `""` key.

## Basic Usage

### mo.cli_args

Get parsed command-line arguments as a read-only, dict-like `CLIArgs` object (`get`, `get_all`, `keys`, `items`, `to_dict`, `in`; `args["missing"]` returns `None`).

```python
import marimo as mo

# Get CLI args (dict-like object)
args = mo.cli_args()

# Read argument with default
learning_rate = args.get("lr", 0.001)
epochs = args.get("epochs", 10)

# Check if argument provided
if "output" in args:
    save_results(args["output"])
```

## Running with Arguments

### From Command Line

```bash
# Basic usage
python notebook.py --lr 0.001 --epochs 50

# Multiple arguments
python notebook.py --input data.csv --output results.json --verbose=true

# With inline (PEP 723) dependencies
uv run notebook.py --lr 0.001

# With marimo commands (note the --)
marimo edit notebook.py -- --lr 0.001
marimo run notebook.py -- --config production
marimo export html notebook.py -o out.html -- --lr 0.001
```

### Argument Formats

```bash
# Key-value pairs (single dash works too: -name value)
python notebook.py --name value
python notebook.py --name=value

# Booleans need an explicit value
python notebook.py --verbose=true
python notebook.py --debug=false

# A bare flag becomes an empty string (falsy!)
python notebook.py --verbose
# Results in: {"verbose": ""}

# Numeric values auto-converted
python notebook.py --count=10      # int
python notebook.py --rate=0.5      # float

# Lists (repeated arguments)
python notebook.py --tag important --tag urgent
# Results in: {"tag": ["important", "urgent"]}
```

## Type Conversion

`mo.cli_args()` automatically converts string arguments:

| Input | Parsed Type | Value |
|-------|-------------|-------|
| `--count=10` | int | `10` |
| `--rate=0.5` | float | `0.5` |
| `--flag=true` | bool | `True` |
| `--flag=false` | bool | `False` |
| `--flag` | str | `""` |
| `--name=hello` | str | `"hello"` |

## Using sys.argv

For more control, access raw arguments via `sys.argv`. Under `marimo edit`/`run`/`export`, marimo sets it to the notebook filename followed by the arguments after `--`:

```python
import sys

# python notebook.py --lr 0.001 --epochs 50
# marimo edit notebook.py -- --lr 0.001 --epochs 50
# Both give: sys.argv == ["notebook.py", "--lr", "0.001", "--epochs", "50"]

print(sys.argv)
```

## Robust Argument Parsing

marimo's docs recommend `argparse` or `simple-parsing` over `mo.cli_args()`: they declare the arguments and generate help text. Because marimo sets `sys.argv`, they work in scripts and under `marimo edit`/`run`/`export` alike:

### With argparse

```python
import argparse
import sys

parser = argparse.ArgumentParser(description="Training script")
parser.add_argument("--lr", type=float, default=0.001, help="Learning rate")
parser.add_argument("--epochs", type=int, default=10, help="Number of epochs")
parser.add_argument("--model", choices=["cnn", "rnn", "transformer"], default="cnn")
parser.add_argument("--verbose", action="store_true")

args = parser.parse_args()

# Use parsed arguments
learning_rate = args.lr
epochs = args.epochs
model_type = args.model
```

### With simple-parsing

```python
from dataclasses import dataclass
from simple_parsing import parse

@dataclass
class Config:
    lr: float = 0.001
    epochs: int = 10
    model: str = "cnn"
    verbose: bool = False

config = parse(Config)

# Use typed config
learning_rate = config.lr
```

## Conditional Execution

Seed a UI element from a CLI arg. When run as a script, the element just keeps its initial value, so the same code serves both modes:

```python
# Cell 1
threshold_slider = mo.ui.slider(
    0, 1, step=0.05, value=mo.cli_args().get("threshold", 0.5)
)
threshold_slider

# Cell 2
threshold = threshold_slider.value
```

To branch on how the notebook runs, use `mo.app_meta().mode` (`"edit"`, `"run"`, `"script"`, `"test"`, or `None`) or `mo.running_in_notebook()` (`False` under `python notebook.py`). `marimo export` reports `"edit"`, not `"script"`.

## Complete Example

```python
# Cell 1: Parse arguments
import marimo as mo

args = mo.cli_args()

# With defaults
config = {
    "input": args.get("input", "data.csv"),
    "output": args.get("output", "results.json"),
    "threshold": float(args.get("threshold", 0.5)),
    "verbose": args.get("verbose", False)
}

mo.md(f"**Configuration:** {config}")

# Cell 2: Load data
import pandas as pd

df = pd.read_csv(config["input"])
mo.md(f"Loaded {len(df)} rows from `{config['input']}`")

# Cell 3: Process
filtered = df[df["score"] > config["threshold"]]

if config["verbose"]:
    print(f"Filtered to {len(filtered)} rows (threshold: {config['threshold']})")

# Cell 4: Save results
import json

results = filtered.to_dict(orient="records")
with open(config["output"], "w") as f:
    json.dump(results, f)

mo.md(f"Saved results to `{config['output']}`")
```

Run with:

```bash
python notebook.py --input sales.csv --output filtered.json --threshold 0.7 --verbose=true
```

## Best Practices

### Provide Defaults

```python
args = mo.cli_args()

# Always have sensible defaults
input_file = args.get("input", "default_input.csv")
output_file = args.get("output", "output.json")
```

### Validate Arguments

```python
from pathlib import Path

args = mo.cli_args()

input_file = args.get("input")
if input_file and not Path(input_file).exists():
    mo.stop(True, mo.callout(f"Input file not found: {input_file}", kind="danger"))
```

### Document Arguments

```python
# At the top of notebook
mo.md("""
## Usage

~~~bash
python notebook.py --input FILE --output FILE [--threshold FLOAT] [--verbose=true]
~~~

**Arguments:**
- `--input`: Input CSV file (required)
- `--output`: Output JSON file (required)
- `--threshold`: Filter threshold (default: 0.5)
- `--verbose`: Enable verbose output
""")
```

### Handle Script vs Interactive Mode

```python
# Skip interactive-only work (e.g. heavy charts) when run as a script
mo.stop(not mo.running_in_notebook())

chart = make_interactive_chart(df)
chart
```

### Resolve Paths Relative to the Notebook

Scripts run from cron or CI often have a different working directory:

```python
input_file = mo.cli_args().get("input") or mo.notebook_dir() / "data" / "input.csv"
```

## Limitations

- With `marimo` commands, arguments must come after the `--` separator (but not with `python notebook.py`)
- Complex nested structures not supported (use JSON files instead)
- No built-in help generation (use argparse for that)
