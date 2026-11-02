# file_io

## FileIO


```python
class FileIO(typing.Generic)
```

[Alpha] FileIO handle, used in the Sandbox filesystem API.

Deprecated on 2026-03-09. Use the `Sandbox.filesystem` APIs instead.

The API is designed to mimic Python's io.FileIO.

Currently this API is in Alpha and is subject to change. File I/O operations
may be limited in size to 100 MiB, and the throughput of requests is
restricted in the current implementation. For our recommendations on large file transfers
see the Sandbox [filesystem access guide](https://modal.com/docs/guide/sandbox-files).

**Usage**

```python notest
import modal

app = modal.App.lookup("my-app", create_if_missing=True)

sb = modal.Sandbox.create(app=app)
f = sb.open("/tmp/foo.txt", "w")
f.write("hello")
f.close()
```

```python
__init__(self, client, task_id)
```


### create

```python
create(cls, path, mode, client, task_id)
```
Create a new FileIO handle.

### read

```python
read(self, n=None)
```
Read n bytes from the current position, or the entire remaining file if n is None.

### readline

```python
readline(self)
```
Read a single line from the current position.

### readlines

```python
readlines(self)
```
Read all lines from the current position.

### write

```python
write(self, data)
```
Write data to the current position.

Writes may not appear until the entire buffer is flushed, which
can be done manually with `flush()` or automatically when the file is
closed.

### flush

```python
flush(self)
```
Flush the buffer to disk.

### seek

```python
seek(self, offset, whence=0)
```
Move to a new position in the file.

`whence` defaults to 0 (absolute file positioning); other values are 1
(relative to the current position) and 2 (relative to the file's end).

### ls

```python
ls(cls, path, client, task_id)
```
List the contents of the provided directory.

### mkdir

```python
mkdir(cls, path, client, task_id, parents=False)
```
Create a new directory.

### rm

```python
rm(cls, path, client, task_id, recursive=False)
```
Remove a file or directory in the Sandbox.

### watch

```python
watch(cls, path, client, task_id, filter=None, recursive=False, timeout=None)
```


### close

```python
close(self)
```
Flush the buffer and close the file.
## ls

```python
ls(path, client, task_id)
```
List the contents of the provided directory.
## mkdir

```python
mkdir(path, client, task_id, parents=False)
```
Create a new directory.
## rm

```python
rm(path, client, task_id, recursive=False)
```
Remove a file or directory in the Sandbox.
## watch

```python
watch(path, client, task_id, filter=None, recursive=False, timeout=None)
```
Watch a file or directory for changes.
