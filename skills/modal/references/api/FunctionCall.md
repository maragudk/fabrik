# FunctionCall


```python
class FunctionCall(typing.Generic, modal.object.Object)
```

A reference to an executed function call.

Constructed using `.spawn(...)` on a Modal function with the same
arguments that a function normally takes. Acts as a reference to
an ongoing function call that can be passed around and used to
poll or fetch function results at some later time.

Conceptually similar to a Future/Promise/AsyncResult in other contexts and languages.


## hydrate

```python
hydrate(self, client=None)
```
Synchronize the local object with its identity on the Modal server.

It is rarely necessary to call this method explicitly, as most operations
will lazily hydrate when needed. The main use case is when you need to
access object metadata, such as its ID.

*Added in v0.72.39*: This method replaces the deprecated `.resolve()` method.

## logs


```python
logs: FunctionCallLogsManager
```

Access logs for a single `FunctionCall`.

Use [`fetch()`](#logsfetch)
to read logs from a UTC time range, [`tail()`](#logstail)
to read the most recent logs, and [`stream()`](#logsstream)
to follow new logs as they arrive.

**See Also**

- [`modal app logs`](https://modal.com/docs/cli/latest/app#modal-app-logs):
CLI access to logs for an App.


### logs.stream

```python
stream(self, timeout=None)
```
Stream new FunctionCall logs until the timeout is reached.
The timeout specifies the number of seconds to wait between log entries before terminating the stream.
This method will stop when the FunctionCall is observed to have completed,
or when the timeout is reached. The completion check is best-effort; if completion
cannot be determined, the stream will continue until the timeout is reached.

**Parameters**

<Parameter name="timeout" type="float | None" defaultValue="None" description="Number of seconds to wait between log entries before terminating the stream. By default, this will block until it is interrupted." />

**Yields**

`LogEntry` objects as they arrive.

**Usage**

```python notest
function = modal.Function.from_name("my-app", "train")
call = function.spawn()

for entry in call.logs.stream():
    print(entry.message, end="")
```

### logs.tail

```python
tail(self, entries=100, *, source=None)
```
Fetch the most recent FunctionCall logs.

**Parameters**

<Parameter name="entries" type="int" defaultValue="100" description="The number of log entries to return." />
<Parameter name="source" type="LogSource | None" defaultValue="None" description="Filter by source: &#x27;stdout&#x27;, &#x27;stderr&#x27;, or &#x27;system&#x27;." />

**Yields**

`LogEntry` objects in chronological order.

**Usage**

```python notest
function = modal.Function.from_name("my-app", "train")
call = function.spawn()

for entry in call.logs.tail(entries=10):
    print(entry.timestamp, entry.message, end="")
```

### logs.fetch

```python
fetch(self, *, since=None, until=None, source=None, search_text="")
```
Fetch all associated logs corresponding to the date range and filters.

**Parameters**

<Parameter name="since" type="datetime | None" defaultValue="None" description="Start date to fetch logs from. Must be in UTC or timezone-naive, which is interpreted as local time. By default, this will fetch logs from the start of the function call." />
<Parameter name="until" type="datetime | None" defaultValue="None" description="Defaults to current date if None. Must be in UTC or timezone-naive, which is interpreted as local time." />
<Parameter name="source" type="LogSource | None" defaultValue="None" description="Filter by source: &#x27;stdout&#x27;, &#x27;stderr&#x27;, or &#x27;system&#x27;." />
<Parameter name="search_text" type="str" defaultValue="&quot;&quot;" description="Filter by search text." />

**Yields**

`LogEntry` objects in chronological order.

**Usage**

```python notest
function = modal.Function.from_name("my-app", "train")
call = function.spawn()

for entry in call.logs.fetch():
    print(entry.timestamp, entry.message, end="")
```

## num_inputs

```python
num_inputs(self)
```
Get the number of inputs in the function call.

**Returns**

How many inputs this function call includes (e.g. `1` for `.spawn()`, more for `.spawn_map()`).

## get

```python
get(self, timeout=None, *, index=0)
```
Get the result of the index-th input of the function call.

`.spawn()` calls have a single output, so only specifying `index=0` is valid.
A non-zero index is useful when your function has multiple outputs, like via `.spawn_map()`.

This function waits indefinitely by default. It takes an optional
`timeout` argument that specifies the maximum number of seconds to wait,
which can be set to `0` to poll for an output immediately.

The returned coroutine is not cancellation-safe.

**Parameters**

<Parameter name="timeout" type="float | None" defaultValue="None" description="Maximum seconds to wait for a result, or `None` to wait indefinitely." />
<Parameter name="index" type="int" defaultValue="0" description="Which input&#x27;s result to retrieve (typically `0` for `.spawn()`)." />

**Returns**

The deserialized return value from that input.

## iter

```python
iter(self, *, start=0, end=None)
```
Iterate in-order over the results of the function call.

Optionally, specify a range [start, end) to iterate over.

If `end` is not provided, it will iterate over all results.

**Parameters**

<Parameter name="start" type="int" defaultValue="0" description="First input index to include (inclusive)." />
<Parameter name="end" type="int | None" defaultValue="None" description="One past the last index to include, or `None` for all remaining inputs." />

**Yields**

Each result value in index order.

**Usage**

```python
@app.function()
def my_func(a):
    return a ** 2


@app.local_entrypoint()
def main():
    fc = my_func.spawn_map([1, 2, 3, 4])
    assert list(fc.iter()) == [1, 4, 9, 16]
    assert list(fc.iter(start=1, end=3)) == [4, 9]
```

## get_call_graph

```python
get_call_graph(self)
```
Fetch information about the graph of Inputs this FunctionCall is part of.

Note: the call graph data is not populated in real-time, and its capture is best-effort.
We do not recommend relying on this method for critical use cases.

See the [`modal.types`](/docs/sdk/py/latest/types) reference for information
on the return values.

**Returns**

A list of `InputInfo` nodes describing the call graph.

## cancel

```python
cancel(self, terminate_containers=False)
```
Cancel the FunctionCall and terminate its inputs without retrying.

**Parameters**

<Parameter name="terminate_containers" type="bool" defaultValue="False" description="If True, terminate the containers running the cancelled inputs. Any other inputs running concurrently on those containers will be rescheduled." />

## from_id

```python
from_id(cls, function_call_id, client=None)
```
Instantiate a FunctionCall object from an existing ID.

Note that it's only necessary to re-instantiate the `FunctionCall` with this method
if you no longer have access to the original object returned from `Function.spawn`.

**Parameters**

<Parameter name="function_call_id" type="str" description="Object ID of an existing function call (e.g. from `FunctionCall.object_id`)." />
<Parameter name="client" type="&quot;modal.client.Client | None&quot;" defaultValue="None" description="Modal client to use; defaults to `Client.from_env()` when omitted." />

**Returns**

A `FunctionCall` handle for the given ID.

**Usage**

```python notest
# Spawn a FunctionCall and keep track of its object ID
fc = my_func.spawn()
fc_id = fc.object_id

# Later, use the ID to re-instantiate the FunctionCall object
fc = FunctionCall.from_id(fc_id)
result = fc.get()
```

## gather

```python
gather(*function_calls)
```
Wait until all Modal FunctionCall objects have results before returning.

Accepts a variable number of `FunctionCall` objects, as returned by `Function.spawn()`.

Raises an exception from the first failing function call.

*Added in v0.73.69*: This method replaces the deprecated `modal.functions.gather` function.

**Parameters**

<Parameter name="*function_calls" type="&quot;_FunctionCall[T]&quot;" description="`FunctionCall` instances to wait on (same order as the returned sequence)." />

**Returns**

Results in the same order as `function_calls` (like `asyncio.gather`).

**Usage**

```python notest
fc1 = slow_func_1.spawn()
fc2 = slow_func_2.spawn()

result_1, result_2 = modal.FunctionCall.gather(fc1, fc2)
```
