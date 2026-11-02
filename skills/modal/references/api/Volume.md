# Volume


```python
class Volume(modal.object.Object)
```

A writeable volume that can be used to share files between one or more Modal functions.

The contents of a volume is exposed as a filesystem. You can use it to share data between different functions, or
to persist durable state across several instances of the same function.

Unlike a networked filesystem, you need to explicitly reload the volume to see changes made since it was mounted.
Similarly, you need to explicitly commit any changes you make to the volume for the changes to become visible
outside the current container.

Concurrent modification is supported, but concurrent modifications of the same files should be avoided! Last write
wins in case of concurrent modification of the same file - any data the last writer didn't have when committing
changes will be lost!

As a result, volumes are typically not a good fit for use cases where you need to make concurrent modifications to
the same file (nor is distributed file locking supported).

Volumes can only be reloaded if there are no open files for the volume - attempting to reload with open files
will result in an error.

**Usage**

```python
import modal

app = modal.App()
volume = modal.Volume.from_name("my-persisted-volume", create_if_missing=True)

@app.function(volumes={"/root/foo": volume})
def f():
    with open("/root/foo/bar.txt", "w") as f:
        f.write("hello")
    volume.commit()  # Persist changes

@app.function(volumes={"/root/foo": volume})
def g():
    volume.reload()  # Fetch latest changes
    with open("/root/foo/bar.txt", "r") as f:
        print(f.read())
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

## objects


```python
objects: VolumeManager
```

Namespace with methods for managing named Volume objects.


### objects.create

```python
create(self, name, *, version=None, allow_existing=False, environment_name=None,
    client=None, experimental_options=None)
```
Create a new named Volume in the workspace environment.

This does not return a local handle; use `modal.Volume.from_name` to look up the Volume after creation.

Added in v1.1.2.

**Parameters**

<Parameter name="name" type="str" description="Name for the new Volume." />
<Parameter name="version" type="int | None" defaultValue="None" description="Optional VolumeFS backend version (1 or 2); experimental." />
<Parameter name="allow_existing" type="bool" defaultValue="False" description="If True, do nothing when a Volume with this name already exists." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Environment to create in; defaults to the active environment." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use; defaults to `Client.from_env()` when omitted." />
<Parameter name="experimental_options" type="dict[str, Any] | None" defaultValue="None" description="Experimental options to create Volume with." />

**Usage**

```python notest
modal.Volume.objects.create("my-volume")
```

Volumes will be created in the active environment, or another one can be specified:

```python notest
modal.Volume.objects.create("my-volume", environment_name="dev")
```

By default, an error is raised if the Volume already exists; `allow_existing=True` makes that case a no-op:

```python notest
modal.Volume.objects.create("my-volume", allow_existing=True)
```

Note that this method does not return a local instance of the Volume. You can use
`modal.Volume.from_name` to perform a lookup after creation.

### objects.list

```python
list(self, *, max_objects=None, created_before=None, environment_name="",
    client=None)
```
List named Volumes in the workspace environment as hydrated handles.

Results are ordered newest to oldest. By default, all matching Volumes are returned.

Added in v1.1.2.

**Parameters**

<Parameter name="max_objects" type="int | None" defaultValue="None" description="Maximum number of Volumes to return." />
<Parameter name="created_before" type="datetime | str | None" defaultValue="None" description="Only include Volumes created before this time (datetime or ISO date string)." />
<Parameter name="environment_name" type="str" defaultValue="&quot;&quot;" description="Environment to list from; defaults to the active environment." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use; defaults to `Client.from_env()` when omitted." />

**Returns**

Hydrated `Volume` objects for each named Volume in the listing.

**Usage**

```python
volumes = modal.Volume.objects.list()
print([v.name for v in volumes])
```

Volumes will be retrieved from the active environment, or another one can be specified:

```python notest
dev_volumes = modal.Volume.objects.list(environment_name="dev")
```

By default, all named Volumes are returned, newest to oldest. It's also possible to limit the
number of results and to filter by creation date:

```python
volumes = modal.Volume.objects.list(max_objects=10, created_before="2025-01-01")
```

### objects.delete

```python
delete(self, name, *, allow_missing=False, environment_name=None, client=None)
```
Delete a named Volume entirely (not individual files).

Deletion is irreversible and affects any Apps using this Volume.

Added in v1.1.2.

**Parameters**

<Parameter name="name" type="str" description="Name of the Volume to delete." />
<Parameter name="allow_missing" type="bool" defaultValue="False" description="If True, do nothing when the Volume does not exist." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Environment to delete from; defaults to the active environment." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use; defaults to `Client.from_env()` when omitted." />

**Usage**

```python notest
await modal.Volume.objects.delete("my-volume")
```

Volumes will be deleted from the active environment, or another one can be specified:

```python notest
await modal.Volume.objects.delete("my-volume", environment_name="dev")
```

## name

```python
name(self)
```


## with_mount_options

```python
with_mount_options(self, *, read_only=None, sub_path=None)
```
Configure options used when mounting this Volume.

Note that these options are not properties stored with the Volume itself - they can be individually configured
for each Volume - container association.

**Parameters**

<Parameter name="read_only" type="bool | None" defaultValue="None" description="Set this to True to make the Volume read only from within containers." />
<Parameter name="sub_path" type="str | PurePosixPath | None" defaultValue="None" description="Only mount this sub_path directory from the Volume. If the directory doesn&#x27;t exist in the Volume, it will be created when the container starts up." />

**Returns**

A `Volume` handle with the mount options applied.

**Usage**

To mount a volume in read-only mode:

```python
import modal

volume = modal.Volume.from_name("my-volume")

@app.function(volumes={"/mnt": volume.with_mount_options(read_only=True)})
def f():
    return os.mkdir("/mnt/foo")  # not possible!
```

To mount only part of a Volume using sub_path:

```python
import modal

volume = modal.Volume.from_name("my-volume")

@app.function(volumes={"/user_data": volume.with_mount_options(sub_path="/users/my_user")})
def f():
    return os.listdir("/user_data")  # lists data from /users/my_user
```

## from_name

```python
from_name(name, *, environment_name=None, create_if_missing=False, version=None,
    create_options=None, client=None)
```
Reference a Volume by name, optionally creating it on the server first.

Hydration is lazy: metadata is fetched from Modal the first time the handle is used.

**Parameters**

<Parameter name="name" type="str" description="Deployment name of the Volume." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Environment to resolve the name in; defaults to the active environment." />
<Parameter name="create_if_missing" type="bool" defaultValue="False" description="If True, create the Volume when it does not already exist." />
<Parameter name="version" type="&quot;modal_proto.api_pb2.VolumeFsVersion.ValueType | None&quot;" defaultValue="None" description="Optional VolumeFS backend version; must match an existing Volume when set." />
<Parameter name="create_options" type="&quot;VolumeCreateOptions | None&quot;" defaultValue="None" description="Applied when creating the Volume. If an existing Volume, validates options are consistent." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use for loading; defaults to `Client.from_env()` when omitted." />

**Returns**

A `Volume` handle (possibly not yet hydrated).

**Usage**

```python
vol = modal.Volume.from_name("my-volume", create_if_missing=True)

app = modal.App()

@app.function(volumes={"/data": vol})
def f():
    pass
```

## from_id

```python
from_id(volume_id, client=None)
```
Construct a Volume from an id and look up the Volume metadata.

This is a lazy method that defers hydrating the local
object with metadata from Modal servers until the first
time it is actually used.

The ID of a Volume object can be accessed using `.object_id`.

**Parameters**

<Parameter name="volume_id" type="str" description="Volume object ID to attach to." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use for loading; defaults to `Client.from_env()` when omitted." />

**Returns**

A `Volume` handle (possibly not yet hydrated).

**Usage**

```python notest
@app.function()
def my_worker(volume_id: str):
    vol = modal.Volume.from_id(volume_id)
    for entry in vol.listdir("/"):
        print(entry.path)

with modal.Volume.ephemeral() as vol:
    my_worker.remote(vol.object_id)
```

## ephemeral

```python
ephemeral(cls, client=None, environment_name=None, version=None,
    create_options=None)
```
Create an anonymous Volume that exists for the duration of the context manager.

**Parameters**

<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use; defaults to `Client.from_env()` when omitted." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Environment for the ephemeral Volume; defaults to the active environment." />
<Parameter name="version" type="&quot;modal_proto.api_pb2.VolumeFsVersion.ValueType | None&quot;" defaultValue="None" description="Optional VolumeFS backend version for the ephemeral Volume." />
<Parameter name="create_options" type="&quot;VolumeCreateOptions | None&quot;" defaultValue="None" description="Options applied when creating the ephemeral Volume." />

**Usage**

```python
import modal

with modal.Volume.ephemeral() as vol:
    assert vol.listdir("/") == []
```

```python notest
async with modal.Volume.ephemeral() as vol:
    assert await vol.listdir("/") == []
```

## info

```python
info(self)
```
Return information about the Volume object.

## commit

```python
commit(self)
```
Commit changes to a mounted volume.

If successful, the changes made are now persisted in durable storage and available to other containers accessing
the volume.

## reload

```python
reload(self)
```
Make latest committed state of volume available in the running container.

Any uncommitted changes to the volume, such as new or modified files, may implicitly be committed when
reloading.

Reloading will fail if there are open files for the volume.

## iterdir

```python
iterdir(self, path, *, recursive=True)
```
Iterate over all files in a directory in the volume.

Passing a directory path lists all files in the directory. For a file path, return only that
file's description. If `recursive` is set to True, list all files and folders under the path
recursively.

## listdir

```python
listdir(self, path, *, recursive=False)
```
List all files under a path prefix in the modal.Volume.

Passing a directory path lists all files in the directory. For a file path, return only that
file's description. If `recursive` is set to True, list all files and folders under the path
recursively.

## read_file

```python
read_file(self, path)
```
Read a file from the modal.Volume.

Note - this function is primarily intended to be used outside of a Modal App.
For more information on downloading files from a Modal Volume, see
[the guide](https://modal.com/docs/guide/volumes).

**Parameters**

<Parameter name="path" type="str" description="Path to the file inside the Volume." />

**Usage**

```python notest
vol = modal.Volume.from_name("my-modal-volume")
data = b""
for chunk in vol.read_file("1mb.csv"):
    data += chunk
print(len(data))  # == 1024 * 1024
```

## remove_file

```python
remove_file(self, path, recursive=False)
```
Remove a file or directory from a volume.

## copy_files

```python
copy_files(self, src_paths, dst_path, recursive=False)
```
Copy files within the volume from src_paths to dst_path.
The semantics of the copy operation follow those of the UNIX cp command.

The `src_paths` parameter is a list. If you want to copy a single file, you should pass a list with a
single element.

`src_paths` and `dst_path` should refer to the desired location *inside* the volume. You do not need to prepend
the volume mount path.

Note that if the volume is already mounted on the Modal function, you should use normal filesystem operations
like `os.rename()` and then `commit()` the volume. The `copy_files()` method is useful when you don't have
the volume mounted as a filesystem, e.g. when running a script on your local computer.

**Parameters**

<Parameter name="src_paths" type="Sequence[str]" description="Source paths inside the Volume (list of one or more paths)." />
<Parameter name="dst_path" type="str" description="Destination path inside the Volume (file or directory, following ``cp`` semantics)." />
<Parameter name="recursive" type="bool" defaultValue="False" description="Whether to copy directories recursively (V2 volumes only)." />

**Usage**

```python notest
vol = modal.Volume.from_name("my-modal-volume")

vol.copy_files(["bar/example.txt"], "bar2")
vol.copy_files(["bar/example.txt"], "bar/example2.txt")
```

## batch_upload

```python
batch_upload(self, force=False)
```
Initiate a batched upload to a volume.

To allow overwriting existing files, set `force` to `True` (you cannot overwrite existing directories with
uploaded files regardless).

**Parameters**

<Parameter name="force" type="bool" defaultValue="False" description="If True, allow overwriting existing files with uploads (not directories)." />

**Usage**

```python notest
vol = modal.Volume.from_name("my-modal-volume")

with vol.batch_upload() as batch:
    batch.put_file("local-path.txt", "/remote-path.txt")
    batch.put_directory("/local/directory/", "/remote/directory")
    batch.put_file(io.BytesIO(b"some data"), "/foobar")
```

## rename

```python
rename(old_name, new_name, *, client=None, environment_name=None)
```

