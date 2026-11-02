# container_process

## ContainerProcess


```python
class ContainerProcess(typing.Generic)
```

Represents a running process in a container.

Container processes communicate via direct communication with
the Modal worker where the container is running.

```python
__init__(self, process_id, task_id, client, command_router_client,
    stdout=StreamType.PIPE, stderr=StreamType.PIPE, exec_deadline=None,
    text=True, by_line=False)
```


### stdout

```python
stdout(self)
```
StreamReader for the container process's stdout stream.

### stderr

```python
stderr(self)
```
StreamReader for the container process's stderr stream.

### stdin

```python
stdin(self)
```
StreamWriter for the container process's stdin stream.

### returncode

```python
returncode(self)
```


### poll

```python
poll(self)
```
Check if the container process has finished running.

Returns `None` if the process is still running, else returns the exit code.

### wait

```python
wait(self)
```
Wait for the container process to finish running. Returns the exit code.
