# Dict


```python
class Dict(modal.object.Object)
```

Distributed dictionary for storage in Modal apps.

Dict contents can be essentially any object so long as they can be serialized by
`cloudpickle`. This includes other Modal objects. If writing and reading in different
environments (eg., writing locally and reading remotely), it's necessary to have the
library defining the data type installed, with compatible versions, on both sides.
Additionally, cloudpickle serialization is not guaranteed to be deterministic, so it is
generally recommended to use primitive types for keys.

**Lifetime of a Dict and its items**

An individual Dict entry will expire after 7 days of inactivity (no reads or writes). The
Dict entries are written to durable storage.

Legacy Dicts (created before 2025-05-20) will still have entries expire 30 days after being
last added. Additionally, contents are stored in memory on the Modal server and could be lost
due to unexpected server restarts. Eventually, these Dicts will be fully sunset.

**Usage**

```python
from modal import Dict

my_dict = Dict.from_name("my-persisted_dict", create_if_missing=True)

my_dict["some key"] = "some value"
my_dict[123] = 456

assert my_dict["some key"] == "some value"
assert my_dict[123] == 456
```

The `Dict` class offers a few methods for operations that are usually accomplished
in Python with operators, such as `Dict.put` and `Dict.contains`. The advantage of
these methods is that they can be safely called in an asynchronous context by using
the `.aio` suffix on the method, whereas their operator-based analogues will always
run synchronously and block the event loop.

For more examples, see the [guide](https://modal.com/docs/guide/dicts-and-queues#modal-dicts).


## hydrate

```python
hydrate(self, client=None)
```
Synchronize the local object with its identity on the Modal server.

It is rarely necessary to call this method explicitly, as most operations
will lazily hydrate when needed. The main use case is when you need to
access object metadata, such as its ID.

*Added in v0.72.39*: This method replaces the deprecated `.resolve()` method.

## objects


```python
objects: DictManager
```

Namespace with methods for managing named Dict objects.


### objects.create

```python
create(self, name, *, allow_existing=False, environment_name=None, client=None)
```
Create a new named Dict in the workspace environment.

This does not return a local handle; use `modal.Dict.from_name` to look up the Dict after creation.

Added in v1.1.2.

**Parameters**

<Parameter name="name" type="str" description="Name for the new Dict." />
<Parameter name="allow_existing" type="bool" defaultValue="False" description="If True, do nothing when a Dict with this name already exists." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Environment to create in; defaults to the active environment." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use; defaults to `Client.from_env()` when omitted." />

**Usage**

```python notest
modal.Dict.objects.create("my-dict")
```

Dicts will be created in the active environment, or another one can be specified:

```python notest
modal.Dict.objects.create("my-dict", environment_name="dev")
```

By default, an error is raised if the Dict already exists; `allow_existing=True` makes that case a no-op:

```python notest
modal.Dict.objects.create("my-dict", allow_existing=True)
```

Note that this method does not return a local instance of the Dict. You can use
`modal.Dict.from_name` to perform a lookup after creation.

### objects.list

```python
list(self, *, max_objects=None, created_before=None, environment_name="",
    client=None)
```
List named Dicts in the workspace environment as hydrated handles.

Results are ordered newest to oldest. By default, all matching Dicts are returned.

Added in v1.1.2.

**Parameters**

<Parameter name="max_objects" type="int | None" defaultValue="None" description="Maximum number of Dicts to return." />
<Parameter name="created_before" type="datetime | str | None" defaultValue="None" description="Only include Dicts created before this time (datetime or ISO date string)." />
<Parameter name="environment_name" type="str" defaultValue="&quot;&quot;" description="Environment to list from; defaults to the active environment." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use; defaults to `Client.from_env()` when omitted." />

**Returns**

Hydrated `Dict` objects for each named Dict in the listing.

**Usage**

```python
dicts = modal.Dict.objects.list()
print([d.name for d in dicts])
```

Dicts will be retrieved from the active environment, or another one can be specified:

```python notest
dev_dicts = modal.Dict.objects.list(environment_name="dev")
```

By default, all named Dicts are returned, newest to oldest. It's also possible to limit the
number of results and to filter by creation date:

```python
dicts = modal.Dict.objects.list(max_objects=10, created_before="2025-01-01")
```

### objects.delete

```python
delete(self, name, *, allow_missing=False, environment_name=None, client=None)
```
Delete a named Dict entirely (not a single key).

Deletion is irreversible and affects any Apps using this Dict.

Added in v1.1.2.

**Parameters**

<Parameter name="name" type="str" description="Name of the Dict to delete." />
<Parameter name="allow_missing" type="bool" defaultValue="False" description="If True, do nothing when the Dict does not exist." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Environment to delete from; defaults to the active environment." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use; defaults to `Client.from_env()` when omitted." />

**Usage**

```python notest
await modal.Dict.objects.delete("my-dict")
```

Dicts will be deleted from the active environment, or another one can be specified:

```python notest
await modal.Dict.objects.delete("my-dict", environment_name="dev")
```

## name

```python
name(self)
```
Name of the Dict object.

**Usage**

```python
d = modal.Dict.from_name("my-dict")
print(d.name)
```

## ephemeral

```python
ephemeral(cls, *, client=None, environment_name=None)
```
Create an anonymous Dict that exists for the duration of the context manager.

**Parameters**

<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use; defaults to `Client.from_env()` when omitted." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Environment for the ephemeral Dict; defaults to the active environment." />

**Usage**

```python
from modal import Dict

with Dict.ephemeral() as d:
    d["foo"] = "bar"
```

```python notest
async with Dict.ephemeral() as d:
    await d.put.aio("foo", "bar")
```

## from_name

```python
from_name(name, *, environment_name=None, create_if_missing=False, client=None)
```
Reference a named Dict, optionally creating it on the server first.

Hydration is lazy: metadata is fetched from Modal the first time the handle is used.

**Parameters**

<Parameter name="name" type="str" description="Deployment name of the Dict." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Environment to resolve the name in; defaults to the active environment." />
<Parameter name="create_if_missing" type="bool" defaultValue="False" description="If True, create the Dict when it does not already exist." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use for loading; defaults to `Client.from_env()` when omitted." />

**Returns**

A `Dict` handle (possibly not yet hydrated).

**Usage**

```python
d = modal.Dict.from_name("my-dict", create_if_missing=True)
d[123] = 456
```

## from_id

```python
from_id(dict_id, client=None)
```
Construct a Dict from an id and look up the Dict metadata.

This is a lazy method that defers hydrating the local
object with metadata from Modal servers until the first
time it is actually used.

The ID of a Dict object can be accessed using `.object_id`.

**Parameters**

<Parameter name="dict_id" type="str" description="Dict object ID to attach to." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use for loading; defaults to `Client.from_env()` when omitted." />

**Returns**

A `Dict` handle (possibly not yet hydrated).

**Usage**

```python notest
@app.function()
def my_worker(dict_id: str):
    d = modal.Dict.from_id(dict_id)
    d["key"] = "Hello from remote function!"

with modal.Dict.ephemeral() as d:
    my_worker.remote(d.object_id)
    print(d["key"])  # "Hello from remote function!"
```

## info

```python
info(self)
```
Return information about the Dict object.

## clear

```python
clear(self)
```
Remove all items from the Dict.

## get

```python
get(self, key, default=None)
```
Get the value associated with a key.

Returns `default` if key does not exist.

## contains

```python
contains(self, key)
```
Return if a key is present.

## len

```python
len(self)
```
Return the length of the Dict.

Note: This is an expensive operation and will return at most 100,000.

## update

```python
update(self, other=None, **kwargs)
```
Update the Dict with additional items.

## put

```python
put(self, key, value, *, skip_if_exists=False)
```
Add a specific key-value pair to the Dict.

Returns True if the key-value pair was added and False if it wasn't because the key already existed and
`skip_if_exists` was set.

## pop

```python
pop(self, key, default=_NO_DEFAULT)
```
Remove a key from the Dict, returning the value if it exists.

If key is not found, return default if provided, otherwise raise KeyError.

## keys

```python
keys(self)
```
Return an iterator over the keys in this Dict.

Note that (unlike with Python dicts) the return value is a simple iterator,
and results are unordered.

## values

```python
values(self)
```
Return an iterator over the values in this Dict.

Note that (unlike with Python dicts) the return value is a simple iterator,
and results are unordered.

## items

```python
items(self)
```
Return an iterator over the (key, value) tuples in this Dict.

Note that (unlike with Python dicts) the return value is a simple iterator,
and results are unordered.
