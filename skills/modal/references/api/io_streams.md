# io_streams

## StreamReader


```python
class StreamReader(typing.Generic)
```

Retrieve logs from a stream (`stdout` or `stderr`).

As an asynchronous iterable, the object supports the `for` and `async for`
statements. Just loop over the object to read in chunks.


### file_descriptor

```python
file_descriptor(self)
```
Possible values are `1` for stdout and `2` for stderr.

### read

```python
read(self)
```
Fetch the entire contents of the stream until EOF.
## StreamWriter


```python
class StreamWriter(object)
```

Provides an interface to buffer and write logs to a sandbox or container process stream (`stdin`).


### write

```python
write(self, data)
```
Write data to the stream but does not send it immediately.

This is non-blocking and queues the data to an internal buffer. Must be
used along with the `drain()` method, which flushes the buffer.

**Usage**

```python fixture:sandbox
proc = sandbox.exec(
    "bash",
    "-c",
    "while read line; do echo $line; done",
)
proc.stdin.write(b"foo\n")
proc.stdin.write(b"bar\n")
proc.stdin.write_eof()
proc.stdin.drain()
```

### write_eof

```python
write_eof(self)
```
Close the write end of the stream after the buffered data is drained.

If the process was blocked on input, it will become unblocked after
`write_eof()`. This method needs to be used along with the `drain()`
method, which flushes the EOF to the process.

### drain

```python
drain(self)
```
Flush the write buffer and send data to the running process.

This is a flow control method that blocks until data is sent. It returns
when it is appropriate to continue writing data to the stream.

**Usage**

```python notest
writer.write(data)
writer.drain()
```

Async usage:

```python notest
writer.write(data)  # not a blocking operation
await writer.drain.aio()
```
