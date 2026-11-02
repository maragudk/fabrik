# enable_output

```python
enable_output()
```
Context manager that enable output when using the Python SDK.

This will print to stdout and stderr things such as
1. Logs from running functions
2. Status of creating objects
3. Map progress

**Usage**

```python
app = modal.App()
with modal.enable_output():
    with app.run():
        ...
```
