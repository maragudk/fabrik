# is_local

```python
is_local()
```
Indicate the execution context of the current process.

Note: this function specifically returns False when the current process is
running a Modal Function and True in all other cases. It will return True
when called from a child process of a Function or inside a Modal Sandbox,
even though those processes are running on Modal hardware.
