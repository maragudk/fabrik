# SQL API Reference

Query databases and DataFrames using SQL with reactive integration.

## Overview

marimo enables mixing Python and SQL through `mo.sql()`. Query Python DataFrames, databases, files, and APIs, with results returned as DataFrames.

## Installation

```bash
pip install "marimo[sql]"
```

## Basic Usage

### mo.sql

Execute SQL queries. Signature: `mo.sql(query, *, output=True, engine=None)`.

```python
import marimo as mo

# Query a Python DataFrame - reference it by variable name, not {df}
result = mo.sql(f"SELECT * FROM df WHERE value > 100")

# With f-string interpolation for reactivity
threshold = mo.ui.slider(0, 100, value=50)
result = mo.sql(f"SELECT * FROM df WHERE value > {threshold.value}")

# Don't display the result in the cell output
result = mo.sql(f"SELECT * FROM df", output=False)
```

`output` is a bool controlling display, not the result type. Without `engine`, queries run on an in-memory DuckDB connection.

## Creating SQL Cells

Three methods in the editor:
1. Right-click "add cell" → "SQL cell"
2. Convert empty cell via context menu
3. Click SQL button at notebook bottom

A SQL cell is stored as Python: `result = mo.sql(f"""...""")`. Name the result with a leading underscore (`_df`) to keep it private to the cell; a non-underscored name can be referenced from other Python and SQL cells.

## Querying DataFrames

Reference Python DataFrames directly by variable name (interpolating `{sales_df}` would paste the DataFrame's repr into the query):

```python
# Python cell
import pandas as pd
sales_df = pd.DataFrame({"product": ["A", "B"], "revenue": [100, 200]})

# SQL cell
result = mo.sql(f"""
    SELECT product, revenue
    FROM sales_df
    WHERE revenue > 150
""")
```

Results can be chained: query `result` by name in a later SQL cell.

## Database Connections

### UI Method

Click "Add Database Connection" in the SQL cell to configure:
- PostgreSQL
- MySQL
- SQLite
- DuckDB
- Snowflake
- BigQuery

### Code Method

```python
# SQLAlchemy
from sqlalchemy import create_engine
engine = create_engine("postgresql://user:pass@host/db")

# Use in SQL
result = mo.sql(f"SELECT * FROM users LIMIT 10", engine=engine)

# Custom DuckDB connection
import duckdb
duckdb_conn = duckdb.connect("file.db")
result = mo.sql(f"SELECT * FROM events", engine=duckdb_conn)
```

Supported: SQLAlchemy, SQLModel, Ibis, DuckDB, ClickHouse Connect, chDB, and DB-API 2.0 (PEP 249) connections including ADBC drivers. Engines defined as global variables are auto-discovered and appear in the SQL cell's connection dropdown and the Data Sources panel.

## Output Types

The result type is a per-notebook setting (editor settings, top right), not a `mo.sql` argument:

```python
# Native DuckDB relation (recommended for large data)
app = marimo.App(sql_output="native")

# Options: "native", "lazy-polars", "pandas", "polars", "auto" (default)
```

`auto` returns Polars if installed, otherwise Pandas. `native` avoids loading the full result into memory and chains SQL cells cheaply. The user-level default is `default_sql_output` under `[runtime]` in the marimo config.

## Querying Files

```python
# CSV
result = mo.sql(f"SELECT * FROM 'data.csv'")

# Parquet
result = mo.sql(f"SELECT * FROM 'data.parquet'")

# Remote files
result = mo.sql(f"SELECT * FROM 'https://example.com/data.csv'")

# S3
result = mo.sql(f"SELECT * FROM 's3://bucket/path/data.parquet'")
```

## Reactive Queries

SQL integrates with marimo's reactivity:

```python
# Cell 1
category = mo.ui.dropdown(["Electronics", "Books", "Clothing"])

# Cell 2 - re-runs when dropdown changes
filtered = mo.sql(f"""
    SELECT * FROM products
    WHERE category = '{category.value}'
""")
```

### Refreshing Queries

Put a refresh control or button in a SQL comment to re-run the query without changing it:

```python
# Cell 1
refresh = mo.ui.refresh(default_interval="30s")  # or mo.ui.button(label="Refresh")
refresh

# Cell 2
data = mo.sql(f"""
    SELECT * FROM my_table
    -- {refresh}
""")
```

## Escaping Braces

SQL cells are f-strings, so write literal `{`/`}` as `{{`/`}}`:

```python
mo.sql(f"SELECT unnest([{{'a': 42, 'b': 84}}, {{'a': 100, 'b': NULL}}])")
```

## Best Practices

- Set `sql_output="native"` for large datasets
- Reference DataFrames by variable name (`FROM df`), not `{df}`
- Use f-strings for reactive parameter binding
- Database tables take precedence over local DataFrames with same name
