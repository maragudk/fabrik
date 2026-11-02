# NetworkFileSystem


```python
class NetworkFileSystem(modal.object.Object)
```

A shared, writable file system accessible by one or more Modal functions.

By attaching this file system as a mount to one or more functions, they can
share and persist data with each other.

**Note: `NetworkFileSystem` has been deprecated and will be removed.**

**Usage**

```python
import modal

nfs = modal.NetworkFileSystem.from_name("my-nfs", create_if_missing=True)
app = modal.App()

@app.function(network_file_systems={"/root/foo": nfs})
def f():
    pass

@app.function(network_file_systems={"/root/goo": nfs})
def g():
    pass
```

Also see the CLI methods for accessing network file systems:

```
modal nfs --help
```

A `NetworkFileSystem` can also be useful for some local scripting scenarios, e.g.:

```python notest
nfs = modal.NetworkFileSystem.from_name("my-network-file-system")
for chunk in nfs.read_file("my_db_dump.csv"):
    ...
```


## hydrate

```python
hydrate(self, client=None)
```
Synchronize the local object with its identity on the Modal server.

It is rarely necessary to call this method explicitly, as most operations
will lazily hydrate when needed. The main use case is when you need to
access object metadata, such as its ID.

*Added in v0.72.39*: This method replaces the deprecated `.resolve()` method.

## from_name

```python
from_name(name, *, environment_name=None, create_if_missing=False, client=None)
```
Reference a NetworkFileSystem by name, optionally creating it on the server first.

Hydration is lazy: metadata is fetched from Modal the first time the handle is used.

**Parameters**

<Parameter name="name" type="str" description="Deployment name of the network file system." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Environment to resolve the name in; defaults to the active environment." />
<Parameter name="create_if_missing" type="bool" defaultValue="False" description="If True, create the object when it does not already exist." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use for loading; defaults to `Client.from_env()` when omitted." />

**Returns**

A `NetworkFileSystem` handle (possibly not yet hydrated).

**Usage**

```python notest
nfs = NetworkFileSystem.from_name("my-nfs", create_if_missing=True)

@app.function(network_file_systems={"/data": nfs})
def f():
    pass
```

## ephemeral

```python
ephemeral(cls, client=None, environment_name=None)
```
Create an anonymous NetworkFileSystem that exists for the duration of the context manager.

**Parameters**

<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use; defaults to `Client.from_env()` when omitted." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Environment for the ephemeral object; defaults to the active environment." />

**Usage**

```python
with modal.NetworkFileSystem.ephemeral() as nfs:
    assert nfs.listdir("/") == []
```

```python notest
async with modal.NetworkFileSystem.ephemeral() as nfs:
    assert await nfs.listdir("/") == []
```

## delete

```python
delete(name, client=None, environment_name=None)
```


## write_file

```python
write_file(self, remote_path, fp, progress_cb=None)
```
Write from a file object to a path on the network file system, atomically.

Will create any needed parent directories automatically.

If remote_path ends with `/` it's assumed to be a directory and the
file will be uploaded with its current name to that directory.

## read_file

```python
read_file(self, path)
```
Read a file from the network file system

## iterdir

```python
iterdir(self, path)
```
Iterate over all files in a directory in the network file system.

* Passing a directory path lists all files in the directory (names are relative to the directory)
* Passing a file path returns a list containing only that file's listing description
* Passing a glob path (including at least one * or ** sequence) returns all files matching
that glob path (using absolute paths)

## add_local_file

```python
add_local_file(self, local_path, remote_path=None, progress_cb=None)
```


## add_local_dir

```python
add_local_dir(self, local_path, remote_path=None, progress_cb=None)
```


## listdir

```python
listdir(self, path)
```
List all files in a directory in the network file system.

* Passing a directory path lists all files in the directory (names are relative to the directory)
* Passing a file path returns a list containing only that file's listing description
* Passing a glob path (including at least one * or ** sequence) returns all files matching
that glob path (using absolute paths)

## remove_file

```python
remove_file(self, path, recursive=False)
```
Remove a file in a network file system.
