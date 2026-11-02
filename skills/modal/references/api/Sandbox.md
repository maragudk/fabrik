# Sandbox


```python
class Sandbox(modal.object.Object)
```

A `Sandbox` object lets you interact with a running sandbox. This API is similar to Python's
[asyncio.subprocess.Process](https://docs.python.org/3/library/asyncio-subprocess.html#asyncio.subprocess.Process).

Refer to the [guide](https://modal.com/docs/guide/sandbox) on how to spawn and use sandboxes.


## hydrate

```python
hydrate(self, client=None)
```
Synchronize the local object with its identity on the Modal server.

It is rarely necessary to call this method explicitly, as most operations
will lazily hydrate when needed. The main use case is when you need to
access object metadata, such as its ID.

*Added in v0.72.39*: This method replaces the deprecated `.resolve()` method.

## create

```python
create(*args, app=None, name=None, tags=None, image=None, env=None,
    secrets=None, network_file_systems={}, timeout=300, idle_timeout=None,
    workdir=None, gpu=None, cloud=None, region=None, cpu=None, memory=None,
    block_network=False, outbound_cidr_allowlist=None,
    outbound_domain_allowlist=None, inbound_cidr_allowlist=None, volumes={},
    pty=False, encrypted_ports=[], h2_ports=[], unencrypted_ports=[],
    custom_domain=None, proxy=None, include_oidc_identity_token=False,
    readiness_probe=None, verbose=False, experimental_options=None,
    _experimental_enable_snapshot=False, client=None, environment_name=None,
    pty_info=None, cidr_allowlist=None)
```
Create a new Sandbox to run untrusted, arbitrary code.

The Sandbox's corresponding container will be created asynchronously.

**Parameters**

<Parameter name="*args" type="str" description="Set the CMD of the Sandbox, overriding any CMD of the container image." />
<Parameter name="app" type="&quot;modal.app._App | None&quot;" defaultValue="None" description="Associate the sandbox with an app. Required unless creating from a container." />
<Parameter name="name" type="str | None" defaultValue="None" description="Optionally give the sandbox a name. Unique within an app." />
<Parameter name="tags" type="dict[str, str] | None" defaultValue="None" description="Tags to assign to the Sandbox." />
<Parameter name="image" type="_Image | None" defaultValue="None" description="The image to run as the container for the sandbox." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables to set in the Sandbox." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets to inject into the Sandbox as environment variables." />
<Parameter name="network_file_systems" type="dict[str | os.PathLike, _NetworkFileSystem]" defaultValue="&#123;&#125;" description="Network file systems to mount into the sandbox." />
<Parameter name="timeout" type="int" defaultValue="300" description="Maximum lifetime of the sandbox in seconds." />
<Parameter name="idle_timeout" type="int | None" defaultValue="None" description="The amount of time in seconds that a sandbox can be idle before being terminated." />
<Parameter name="workdir" type="str | None" defaultValue="None" description="Working directory of the sandbox." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU reservation for the sandbox." />
<Parameter name="cloud" type="str | None" defaultValue="None" description="Cloud provider for the sandbox." />
<Parameter name="region" type="str | Sequence[str] | None" defaultValue="None" description="Region or regions to run the sandbox on." />
<Parameter name="cpu" type="float | tuple[float, float] | None" defaultValue="None" description="Specify, in fractional CPU cores, how many CPU cores to request. Or, pass (request, limit) to additionally specify a hard limit in fractional CPU cores. CPU throttling will prevent a container from exceeding its specified limit." />
<Parameter name="memory" type="int | tuple[int, int] | None" defaultValue="None" description="Specify, in MiB, a memory request which is the minimum memory required. Or, pass (request, limit) to additionally specify a hard limit in MiB." />
<Parameter name="block_network" type="bool" defaultValue="False" description="Whether to block network access." />
<Parameter name="outbound_cidr_allowlist" type="Sequence[str] | None" defaultValue="None" description="List of CIDRs the sandbox is allowed to access. If None, all CIDRs are allowed." />
<Parameter name="outbound_domain_allowlist" type="Sequence[str] | None" defaultValue="None" description="List of domain names the sandbox is allowed to access. Supports wildcard prefixes (``*.``); a bare ``&quot;*&quot;`` allows all domains. The outbound policy can be replaced later via `Sandbox._experimental_set_outbound_network_policy`." />
<Parameter name="inbound_cidr_allowlist" type="Sequence[str] | None" defaultValue="None" description="List of CIDRs allowed to connect inbound to the sandbox (tunnels and connection tokens). If None, all CIDRs are allowed." />
<Parameter name="volumes" type="dict[str | os.PathLike, _Volume | _CloudBucketMount]" defaultValue="&#123;&#125;" description="Mount points for Modal Volumes and CloudBucketMounts." />
<Parameter name="pty" type="bool" defaultValue="False" description="Enable a PTY for the Sandbox entrypoint command. When enabled, all output (stdout and stderr from the process) is multiplexed into stdout, and the stderr stream is effectively empty." />
<Parameter name="encrypted_ports" type="Sequence[int]" defaultValue="[]" description="List of ports to tunnel into the sandbox. Encrypted ports are tunneled with TLS." />
<Parameter name="h2_ports" type="Sequence[int]" defaultValue="[]" description="List of encrypted ports to tunnel into the sandbox, using HTTP/2." />
<Parameter name="unencrypted_ports" type="Sequence[int]" defaultValue="[]" description="List of ports to tunnel into the sandbox without encryption." />
<Parameter name="custom_domain" type="str | None" defaultValue="None" description="Allow connections to the Sandbox via a subdomain of this parent rather than a default Modal domain." />
<Parameter name="proxy" type="_Proxy | None" defaultValue="None" description="Reference to a Modal Proxy to use in front of this Sandbox." />
<Parameter name="include_oidc_identity_token" type="bool" defaultValue="False" description="If True, the sandbox will receive a MODAL_IDENTITY_TOKEN env var for OIDC-based auth." />
<Parameter name="readiness_probe" type="Probe | None" defaultValue="None" description="Probe used to determine when the sandbox has become ready." />
<Parameter name="verbose" type="bool" defaultValue="False" description="Enable verbose logging for sandbox operations." />
<Parameter name="experimental_options" type="dict[str, Any] | None" defaultValue="None" description="Experimental options to pass to the sandbox." />
<Parameter name="_experimental_enable_snapshot" type="bool" defaultValue="False" description="Enable memory snapshots." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal Client to use for the sandbox." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="*DEPRECATED* Optionally override the default environment" />
<Parameter name="pty_info" type="api_pb2.PTYInfo | None" defaultValue="None" description="*DEPRECATED* Use `pty` instead. `pty` will override `pty_info`." />
<Parameter name="cidr_allowlist" type="Sequence[str] | None" defaultValue="None" description="*DEPRECATED* Use outbound_cidr_allowlist instead." />

**Returns**

A `Sandbox` object representing the created sandbox which can be used to interact with the sandbox.

**Raises**

- `AlreadyExistsError`: If a sandbox with the same name already exists.

**Usage**

```python
app = modal.App.lookup('sandbox-hello-world', create_if_missing=True)
sandbox = modal.Sandbox.create("echo", "hello world", app=app)
print(sandbox.stdout.read())
sandbox.wait()
```

## detach

```python
detach(self)
```
Disconnects your client from the sandbox and cleans up resources assoicated with the connection.

Be sure to only call `detach` when you are done interacting with the sandbox. After calling `detach`,
any operation using the Sandbox object is not guaranteed to work anymore. If you want to continue interacting
with a running sandbox, use `Sandbox.from_id` to get a new Sandbox object.

## from_name

```python
from_name(app_name, name, *, environment_name=None, client=None)
```
Get a running Sandbox by name from a deployed App.

A Sandbox's name is the `name` argument passed to `Sandbox.create`.

**Parameters**

<Parameter name="app_name" type="str" description="Name of the deployed app to look up the sandbox under." />
<Parameter name="name" type="str" description="Sandbox name to resolve." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Optional environment name for the lookup; defaults to the configured environment." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use for the RPC; defaults to `Client.from_env()` when omitted." />

**Returns**

A `Sandbox` handle for the running sandbox.

**Raises**

- `NotFoundError`: If no running sandbox exists with the given name.

## from_id

```python
from_id(sandbox_id, client=None)
```
Construct a Sandbox from an id and look up the Sandbox result.

The ID of a Sandbox object can be accessed using `.object_id`.

**Parameters**

<Parameter name="sandbox_id" type="str" description="Sandbox object ID to attach to." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use for the lookup; defaults to the environment client when omitted." />

**Returns**

A `Sandbox` handle with any available result metadata populated from the server.

## get_tags

```python
get_tags(self)
```
Fetches any tags (key-value pairs) currently attached to this Sandbox from the server.

**Returns**

Tags as a map from tag name to tag value.

## set_tags

```python
set_tags(self, tags, *, client=None)
```
Set tags (key-value pairs) on the Sandbox. Tags can be used to filter results in `Sandbox.list`.

Setting tags replaces the Sandbox's entire tag set; passing an empty dict clears all tags.

**Parameters**

<Parameter name="tags" type="dict[str, str]" description="Tag names and values to set on this sandbox." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Deprecated. Prefer setting the client when creating or re-attaching to the sandbox." />

## snapshot_filesystem

```python
snapshot_filesystem(self, timeout=55, *, ttl=30 * 24 * 3600)
```
Snapshot the filesystem of the Sandbox.

**Parameters**

<Parameter name="timeout" type="int" defaultValue="55" description="Maximum time in seconds to wait for the snapshot operation. If the snapshot does not return within that window, the call is cancelled and `modal.exception.TimeoutError` is raised." />
<Parameter name="ttl" type="int | None" defaultValue="30 * 24 * 3600" description="The resulting Image is retained for `ttl` seconds (default: 30 days). Pass `ttl=None` to retain the image indefinitely." />

**Returns**

An [`Image`](https://modal.com/docs/sdk/py/latest/Image) object which can be used to spawn a new
Sandbox with the same filesystem.

## mount_image

```python
mount_image(self, path, image, *, _experimental_encryption_key=None)
```
Mount an Image at a specified path in a running Sandbox.

`path` should be a directory that is **not** the root path (`/`). If the path doesn't exist
it will be created. If it exists and contains data, the previous directory will be replaced
by the mount.

The `image` argument supports any Image that has an object ID, including:
- Images built using `image.build()`
- Images referenced by ID, e.g. `Image.from_id(...)`
- Filesystem/directory snapshots, e.g. created by `.snapshot_directory()` or `.snapshot_filesystem()`
- Empty images created with `Image.from_scratch()`

**Parameters**

<Parameter name="path" type="PurePosixPath | str" description="Absolute mount point directory inside the sandbox (not `/`)." />
<Parameter name="image" type="_Image" description="Image to mount at `path` (must be built, referenced by ID, or snapshot-based as described above)." />

**Usage**

```py notest
user_project_snapshot: Image = sandbox_session_1.snapshot_directory("/user_project")

# You can later mount this snapshot to another Sandbox:
sandbox_session_2 = modal.Sandbox.create(...)
sandbox_session_2.mount_image("/user_project", user_project_snapshot)
sandbox_session_2.filesystem.list_files("/user_project")
```

## unmount_image

```python
unmount_image(self, path)
```
Unmount a previously mounted Image from a running Sandbox.

`path` must be the exact mount point that was passed to `.mount_image()`.
After unmounting, the underlying Sandbox filesystem at that path becomes
visible again.

**Parameters**

<Parameter name="path" type="PurePosixPath | str" description="Absolute mount point directory to unmount." />

## snapshot_directory

```python
snapshot_directory(self, path, *, timeout=55, ttl=30 * 24 * 3600,
    _experimental_encryption_key=None)
```
Snapshot a directory in a running Sandbox, creating a new Image with its content.

`timeout` If the snapshot does not return within that window, the call is cancelled
and `modal.exception.TimeoutError` is raised.

`ttl` The resulting Image is retained for `ttl` seconds (default: 30 days)
Pass `ttl=None` to retain the image indefinitely.

**Parameters**

<Parameter name="path" type="PurePosixPath | str" description="Absolute path of the directory inside the sandbox to snapshot." />

**Returns**

An `Image` containing the directory contents.

**Usage**

```py notest
user_project_snapshot: Image = sandbox_session_1.snapshot_directory("/user_project")

# You can later mount this snapshot to another Sandbox:
sandbox_session_2 = modal.Sandbox.create(...)
sandbox_session_2.mount_image("/user_project", user_project_snapshot)
sandbox_session_2.filesystem.list_files("/user_project")
```

## wait

```python
wait(self, raise_on_termination=True)
```
Wait for the Sandbox to finish running.

**Parameters**

<Parameter name="raise_on_termination" type="bool" defaultValue="True" description="If True, raise when the sandbox is terminated externally." />

## wait_until_ready

```python
wait_until_ready(self, *, timeout=300)
```
Wait for the Sandbox readiness probe to report that the Sandbox is ready.

The Sandbox must be configured with a `readiness_probe` in order to use this method.

**Parameters**

<Parameter name="timeout" type="int" defaultValue="300" description="Maximum time in seconds to wait for readiness." />

**Usage**

```py notest
app = modal.App.lookup('sandbox-wait-until-ready', create_if_missing=True)
sandbox = modal.Sandbox.create(
    "python3", "-m", "http.server", "8080",
    readiness_probe=modal.Probe.with_tcp(8080),
    app=app,
)
sandbox.wait_until_ready()
```

## tunnels

```python
tunnels(self, timeout=50)
```
Get Tunnel metadata for the sandbox.

NOTE: Previous to client [v0.64.153](https://modal.com/docs/sdk/py/changelog#064153-2024-09-30), this
returned a list of `TunnelData` objects.

**Parameters**

<Parameter name="timeout" type="int" defaultValue="50" description="Maximum time in seconds to wait for tunnel metadata when not already cached." />

**Returns**

A dictionary mapping container port to `Tunnel` metadata.

**Raises**

- `SandboxTimeoutError`: If the tunnels are not available after the timeout.

## create_connect_token

```python
create_connect_token(self, user_metadata=None, port=8080)
```
Create a token for making HTTP connections to the Sandbox.

Accepts an optional user_metadata string or dict to associate with the token. This metadata
will be added to the headers by the proxy when forwarding requests to the Sandbox.
Also accepts a port that requests will be routed to.

**Parameters**

<Parameter name="user_metadata" type="str | dict[str, Any] | None" defaultValue="None" description="Optional JSON-serializable metadata or string stored with the connect token." />
<Parameter name="port" type="int" defaultValue="8080" description="Optional container port that requests are routed to when using this token." />

**Returns**

URL and token credentials for connecting to the sandbox over HTTP.

## reload_volumes

```python
reload_volumes(self, *, timeout=55)
```
Reload all Volumes mounted in the Sandbox.

Added in v1.1.0.

Blocks until the reload completes, or raises `modal.exception.TimeoutError` on timeout (the reload
may still complete in the background).

**Parameters**

<Parameter name="timeout" type="int" defaultValue="55" description="Defaults to 55 seconds." />

## terminate

```python
terminate(self, *, wait=False)
```
Terminate Sandbox execution.

This is a no-op if the Sandbox has already finished running.

**Parameters**

<Parameter name="wait" type="bool" defaultValue="False" description="If True, block until termination completes and return the exit code." />

**Returns**

The sandbox exit code when `wait` is True; otherwise None.

## poll

```python
poll(self)
```
Check if the Sandbox has finished running.

**Returns**

`None` if the Sandbox is still running, otherwise the exit code.

## exec

```python
exec(self, *args, stdout=StreamType.PIPE, stderr=StreamType.PIPE, timeout=None,
    workdir=None, env=None, secrets=None, text=True, bufsize=-1, pty=False,
    _pty_info=None, pty_info=None)
```
Execute a command in the Sandbox and return a ContainerProcess handle.

See the [`ContainerProcess`](https://modal.com/docs/sdk/py/latest/container_process#containerprocess)
docs for more information.

**Parameters**

<Parameter name="*args" type="str" description="Command and arguments to run inside the sandbox." />
<Parameter name="stdout" type="StreamType" defaultValue="StreamType.PIPE" description="Where to connect the process stdout stream." />
<Parameter name="stderr" type="StreamType" defaultValue="StreamType.PIPE" description="Where to connect the process stderr stream." />
<Parameter name="timeout" type="int | None" defaultValue="None" description="Optional timeout in seconds for the exec session." />
<Parameter name="workdir" type="str | None" defaultValue="None" description="Working directory for the command; must be absolute if set." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables to set during command execution." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets to inject as environment variables during command execution." />
<Parameter name="text" type="bool" defaultValue="True" description="If True, decode streams as text; if False, yield bytes." />
<Parameter name="bufsize" type="Literal[-1, 1]" defaultValue="-1" description="Control line-buffered output. ``-1`` means unbuffered; ``1`` means line-buffered (only when ``text`` is True)." />
<Parameter name="pty" type="bool" defaultValue="False" description="Enable a PTY for the command. When enabled, all output (stdout and stderr from the process) is multiplexed into stdout, and the stderr stream is effectively empty." />
<Parameter name="_pty_info" type="api_pb2.PTYInfo | None" defaultValue="None" description="*DEPRECATED* Use `pty` instead. `pty` will override `_pty_info`." />
<Parameter name="pty_info" type="api_pb2.PTYInfo | None" defaultValue="None" description="*DEPRECATED* Use `pty` instead. `pty` will override `pty_info`." />

**Returns**

A `ContainerProcess` handle for the running command (text or bytes depending on `text`).

**Usage**

```python fixture:sandbox
process = sandbox.exec("bash", "-c", "for i in $(seq 1 3); do echo foo $i; sleep 0.1; done")
for line in process.stdout:
    print(line)
```

## filesystem


```python
filesystem: SandboxFilesystem
```

Namespace for Sandbox filesystem APIs.


### filesystem.copy_from_local

```python
copy_from_local(self, local_path, remote_path)
```
Copy a local file into the Sandbox.

`remote_path` must be an absolute path to a file in the Sandbox.
Parent directories for `remote_path` are created if needed.
The remote file is overwritten if it already exists.

**Parameters**

<Parameter name="local_path" type="str | os.PathLike" description="Path to the file on the local machine." />
<Parameter name="remote_path" type="str" description="Absolute path to the file in the Sandbox." />

**Raises**

- `SandboxFilesystemNotADirectoryError`: A parent path component of ``remote_path`` is not a directory.
- `SandboxFilesystemIsADirectoryError`: ``remote_path`` points to a directory.
- `SandboxFilesystemPermissionError`: Write permission is denied in the Sandbox.
- `SandboxFilesystemError`: The command fails for any other reason.
- `FileNotFoundError`: ``local_path`` does not exist.
- `IsADirectoryError`: ``local_path`` is a directory.
- `PermissionError`: Reading ``local_path`` is not permitted.

**Usage**

```python fixture:sandbox fixture:tmpdir
import tempfile
from pathlib import Path

local_path = Path(tempfile.mktemp())
local_path.write_text("Hello, world!\n")
sandbox.filesystem.copy_from_local(local_path, "/tmp/hello.txt")
```

### filesystem.copy_to_local

```python
copy_to_local(self, remote_path, local_path)
```
Copy a file from the Sandbox to a local path.

`remote_path` must be an absolute path to a file in the Sandbox.
Parent directories for `local_path` are created if needed.
The local file is overwritten if it already exists.

**Raises**

- `SandboxFilesystemNotFoundError`: the remote path does not exist.
- `SandboxFilesystemIsADirectoryError`: the remote path points to a directory.
- `SandboxFilesystemPermissionError`: read permission is denied in the Sandbox.
- `SandboxFilesystemError`: the command fails for any other reason.
- `IsADirectoryError`: `local_path` points to a directory.
- `NotADirectoryError`: a component of the `local_path` parent is not a directory.
- `PermissionError`: writing `local_path` is not permitted.

**Usage**

```python fixture:sandbox fixture:tmpdir
sandbox.filesystem.write_text("Hello, world!\n", "/tmp/hello.txt")
sandbox.filesystem.copy_to_local("/tmp/hello.txt", "/tmp/local-hello.txt")
```

### filesystem.list_files

```python
list_files(self, remote_path)
```
List files and directories in a Sandbox directory.

**Parameters**

<Parameter name="remote_path" type="str" description="Absolute path to the directory in the Sandbox." />

**Returns**

A list of `FileInfo` objects describing each entry.

**Raises**

- `SandboxFilesystemNotFoundError`: The path does not exist.
- `SandboxFilesystemNotADirectoryError`: The path is not a directory.
- `SandboxFilesystemPermissionError`: Read permission is denied.
- `SandboxFilesystemError`: The command fails for any other reason.

**Usage**

```python fixture:sandbox
entries = sandbox.filesystem.list_files("/tmp")
for entry in entries:
    print(entry.name, entry.type, entry.size)
```

### filesystem.make_directory

```python
make_directory(self, remote_path, *, create_parents=True)
```
Create a new directory in the Sandbox.

`remote_path` must be an absolute path in the Sandbox.

When `create_parents` is `True` (the default), any missing parent directories are created and the call is
idempotent (succeeds silently if the directory already exists). When `create_parents` is `False`, the
immediate parent directory must already exist and the path must not already exist.

**Parameters**

<Parameter name="remote_path" type="str" description="Absolute path of the directory to create in the Sandbox." />
<Parameter name="create_parents" type="bool" defaultValue="True" description="When ``True``, create missing parents and succeed if the directory already exists." />

**Raises**

- `SandboxFilesystemNotFoundError`: The parent directory does not exist and ``create_parents`` is false.
- `SandboxFilesystemPathAlreadyExistsError`: The path already exists.
- `SandboxFilesystemNotADirectoryError`: A path component is not a directory.
- `SandboxFilesystemPermissionError`: Creation is not permitted.
- `InvalidError`: The operation is not supported by the mount.
- `SandboxFilesystemError`: The command fails for any other reason.

**Usage**

```python fixture:sandbox
sandbox.filesystem.make_directory("/tmp/a/b/c")
```

### filesystem.read_bytes

```python
read_bytes(self, remote_path)
```
Read a file from the Sandbox and return its contents as bytes.

`remote_path` must be an absolute path to a file in the Sandbox.

**Parameters**

<Parameter name="remote_path" type="str" description="Absolute path to the file in the Sandbox." />

**Returns**

Raw bytes read from the file.

**Raises**

- `SandboxFilesystemNotFoundError`: The path does not exist.
- `SandboxFilesystemIsADirectoryError`: The path points to a directory.
- `SandboxFilesystemPermissionError`: Read permission is denied.
- `SandboxFilesystemError`: The command fails for any other reason.

**Usage**

```python fixture:sandbox
sandbox.filesystem.write_bytes(b"Hello, world!\n", "/tmp/hello.bin")
contents = sandbox.filesystem.read_bytes("/tmp/hello.bin")
print(contents.decode("utf-8"))
```

### filesystem.read_text

```python
read_text(self, remote_path)
```
Read a file from the Sandbox and return its contents as a UTF-8 string.

`remote_path` must be an absolute path to a file in the Sandbox.

**Parameters**

<Parameter name="remote_path" type="str" description="Absolute path to the file in the Sandbox." />

**Returns**

File contents decoded as UTF-8.

**Raises**

- `SandboxFilesystemNotFoundError`: The path does not exist.
- `SandboxFilesystemIsADirectoryError`: The path points to a directory.
- `SandboxFilesystemPermissionError`: Read permission is denied.
- `SandboxFilesystemError`: The command fails for any other reason.

**Usage**

```python fixture:sandbox
sandbox.filesystem.write_text("Hello, world!\n", "/tmp/hello.txt")
contents = sandbox.filesystem.read_text("/tmp/hello.txt")
print(contents)
```

### filesystem.remove

```python
remove(self, remote_path, *, recursive=False)
```
Remove a file or directory in the Sandbox.

When `remote_path` is a directory and `recursive` is `False` (the
default), removes it only if it is empty. When `recursive` is `True`,
removes the directory and all its contents.

Recursive directory removal is not supported on all mounts.
In particular, `CloudBucketMount` does not support it. An
`InvalidError` is raised in that case.

**Parameters**

<Parameter name="remote_path" type="str" description="Absolute path to the file in the Sandbox." />
<Parameter name="recursive" type="bool" defaultValue="False" description="When ``True``, remove the directory and all its contents." />

**Raises**

- `SandboxFilesystemNotFoundError`: The remote path does not exist.
- `SandboxFilesystemDirectoryNotEmptyError`: `recursive` is `False` and the directory is not empty.
- `SandboxFilesystemPermissionError`: Read permission is denied in the Sandbox.
- `InvalidError`: The operation is not supported by the mount.
- `SandboxFilesystemError`: The command fails for any other reason.

**Usage**

To remove a file:

```python fixture:sandbox
sandbox.filesystem.write_bytes(b"Hello, world!\n", "/tmp/hello.bin")
sandbox.filesystem.remove("/tmp/hello.bin")
```

To remove a directory and all its contents:

```python fixture:sandbox
sandbox.filesystem.make_directory("/tmp/mydir/subdir")
sandbox.filesystem.remove("/tmp/mydir", recursive=True)
```

### filesystem.stat

```python
stat(self, remote_path)
```
Return metadata for a single file, directory, or symlink in the Sandbox.

`remote_path` must be an absolute path in the Sandbox. If `remote_path` is a symlink, the returned
`FileInfo` object describes the symlink, not the target it points to.

**Raises**

- `SandboxFilesystemNotFoundError`: the path does not exist.
- `SandboxFilesystemNotADirectoryError`: a non-leaf component of the path is not a directory.
- `SandboxFilesystemPermissionError`: a component of the path is not searchable.
- `SandboxFilesystemError`: the command fails for any other reason.

**Usage**

```python fixture:sandbox
sandbox.filesystem.write_text("Hello, world!\n", "/tmp/hello.txt")
info = sandbox.filesystem.stat("/tmp/hello.txt")
print(info.size, info.permissions, info.modified_time)
```

### filesystem.watch

```python
watch(self, remote_path, *, filter=None, recursive=False, timeout=None)
```
Watch a path in the Sandbox for filesystem changes.

`remote_path` must be an absolute path in the Sandbox. If it points
to a file, events for that file are reported. If it points to a
directory, events for entries directly inside it are reported. Set
`recursive=True` to also receive events for all nested subdirectories.
If `remote_path` is a symlink, it is followed and events reference
paths under the resolved target.

Yields `FileWatchEvent` objects as changes occur, until either
`timeout` seconds elapse, the iterator is closed, or the Sandbox
is terminated.

Optionally restrict the kinds of events emitted to those included
in `filter`. The default filter `None` permits all event types.

`timeout` is in seconds. `None` means watch indefinitely. When
`timeout` elapses, the iterator stops without raising an exception.

**Raises**

- `SandboxFilesystemNotFoundError`: `remote_path` does not exist.
- `SandboxFilesystemPermissionError`: watch access is denied.
- `InvalidError`: the filesystem at `remote_path` does not support
  watching.
- `SandboxFilesystemError`: the command fails for any other reason.

**Usage**

```python notest
for event in sandbox.filesystem.watch(
    "/tmp/foo",
    recursive=True,
    filter=[FileWatchEventType.Create],
    timeout=60,
):
    if any(p.endswith(".done") for p in event.paths):
        break
```

### filesystem.write_bytes

```python
write_bytes(self, data, remote_path)
```
Write binary content to a file in the Sandbox.

`remote_path` must be an absolute path to a file in the Sandbox.
Parent directories for `remote_path` are created if needed.
The remote file is overwritten if it already exists.

**Parameters**

<Parameter name="data" type="bytes | bytearray | memoryview" description="Bytes to write." />
<Parameter name="remote_path" type="str" description="Absolute path to the file in the Sandbox." />

**Raises**

- `TypeError`: ``data`` is not bytes-like.
- `SandboxFilesystemNotADirectoryError`: A parent path component is not a directory.
- `SandboxFilesystemIsADirectoryError`: ``remote_path`` points to a directory.
- `SandboxFilesystemPermissionError`: Write permission is denied.
- `SandboxFilesystemError`: The command fails for any other reason.

**Usage**

```python fixture:sandbox
sandbox.filesystem.write_bytes(b"Hello, world!\n", "/tmp/hello.bin")
```

### filesystem.write_text

```python
write_text(self, data, remote_path)
```
Write UTF-8 text to a file in the Sandbox.

`remote_path` must be an absolute path to a file in the Sandbox.
Parent directories for `remote_path` are created if needed.
The remote file is overwritten if it already exists.

**Parameters**

<Parameter name="data" type="str" description="Text to write (encoded as UTF-8)." />
<Parameter name="remote_path" type="str" description="Absolute path to the file in the Sandbox." />

**Raises**

- `TypeError`: ``data`` is not a string.
- `SandboxFilesystemNotADirectoryError`: A parent path component is not a directory.
- `SandboxFilesystemIsADirectoryError`: ``remote_path`` points to a directory.
- `SandboxFilesystemPermissionError`: Write permission is denied.
- `SandboxFilesystemError`: The command fails for any other reason.

**Usage**

```python fixture:sandbox
sandbox.filesystem.write_text("Hello, world!\n", "/tmp/hello.txt")
```

## open

```python
open(self, path, mode="r")
```
[Alpha] Open a file in the Sandbox and return a FileIO handle.

**Deprecated (2026-03-09):** Use the `Sandbox.filesystem` APIs instead for improved reliability.

See the [`FileIO`](https://modal.com/docs/sdk/py/latest/file_io#fileio)
docs for more information.

**Parameters**

<Parameter name="path" type="str" description="Absolute path of the file inside the sandbox." />
<Parameter name="mode" type="Union[_typeshed.OpenTextMode, _typeshed.OpenBinaryMode]" defaultValue="&quot;r&quot;" description="File open mode (text or binary), following built-in ``open`` conventions." />

**Returns**

A `FileIO` handle for reading or writing the remote file.

**Usage**

```python notest
sb = modal.Sandbox.create(app=sb_app)
f = sb.open("/test.txt", "w")
f.write("hello")
f.close()
```

## ls

```python
ls(self, path)
```
[Alpha] List the contents of a directory in the Sandbox.

**Deprecated (2026-04-15):** Use `Sandbox.filesystem.list_files()` instead for improved reliability.

**Parameters**

<Parameter name="path" type="str" description="Absolute directory path inside the sandbox." />

**Returns**

Entry names in the directory as a list of strings.

## mkdir

```python
mkdir(self, path, parents=False)
```
[Alpha] Create a new directory in the Sandbox.

**Deprecated (2026-04-15):** Use `Sandbox.filesystem.make_directory()` instead for improved reliability.

## rm

```python
rm(self, path, recursive=False)
```
[Alpha] Remove a file or directory in the Sandbox.

**Deprecated (2026-04-15):** Use `Sandbox.filesystem.remove()` instead for improved reliability.

## watch

```python
watch(self, path, filter=None, recursive=None, timeout=None)
```
[Alpha] Watch a file or directory in the Sandbox for changes.

**Deprecated (2026-05-08):** Use `Sandbox.filesystem.watch()` instead for improved reliability.

**Parameters**

<Parameter name="path" type="str" description="Absolute path to watch." />
<Parameter name="filter" type="builtins.list[FileWatchEventType] | None" defaultValue="None" description="Optional list of event types to include." />
<Parameter name="recursive" type="bool | None" defaultValue="None" description="Whether to watch subdirectories; None uses server defaults." />
<Parameter name="timeout" type="int | None" defaultValue="None" description="Optional timeout for the watch stream." />

**Returns**

An async iterator of `FileWatchEvent` values.

## stdout

```python
stdout(self)
```
[`StreamReader`](https://modal.com/docs/sdk/py/latest/io_streams#streamreader)
for the sandbox's stdout stream.

**Returns**

Stream reader for sandbox stdout.

## stderr

```python
stderr(self)
```
[`StreamReader`](https://modal.com/docs/sdk/py/latest/io_streams#streamreader)
for the Sandbox's stderr stream.

**Returns**

Stream reader for sandbox stderr.

## stdin

```python
stdin(self)
```
[`StreamWriter`](https://modal.com/docs/sdk/py/latest/io_streams#streamwriter)
for the Sandbox's stdin stream.

**Returns**

Stream writer for sandbox stdin.

## returncode

```python
returncode(self)
```
Return code of the Sandbox process if it has finished running, else `None`.

**Returns**

Exit code when the sandbox process has completed, otherwise None.

## list

```python
list(*, app_id=None, tags=None, client=None)
```
List all Sandboxes for the current Environment or App ID (if specified). If tags are specified, only
Sandboxes that have at least those tags are returned.

**Parameters**

<Parameter name="app_id" type="str | None" defaultValue="None" description="If set, restrict results to sandboxes under this app ID." />
<Parameter name="tags" type="dict[str, str] | None" defaultValue="None" description="If set, only sandboxes containing at least these tags are returned." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use for listing; defaults to `Client.from_env()` when omitted." />

**Returns**

An async generator yielding `Sandbox` objects.

## logs


```python
logs: SandboxLogsManager
```

Access logs for a `Sandbox` entrypoint.

Useful for inspecting logs after a Sandbox terminates.
Use [`fetch()`](#logsfetch)
to read logs from a UTC time range, [`tail()`](#logstail)
to read the most recent logs.

Note that the logs from executed commands in the sandbox (via `exec()`) are not included in the
entrypoint logs.

**See Also**

- [`modal app logs`](https://modal.com/docs/cli/latest/app#modal-app-logs):
  CLI access to logs for an App.


### logs.fetch

```python
fetch(self, *, since, until=None, source=None, search_text="")
```
Fetch Sandbox logs corresponding to the date range and filters.

**Parameters**

<Parameter name="since" type="datetime" description="Start date to fetch logs from. Must be in UTC or timezone-naive, which is interpreted as local time." />
<Parameter name="until" type="datetime | None" defaultValue="None" description="Defaults to current date if None. Must be in UTC or timezone-naive, which is interpreted as local time." />
<Parameter name="source" type="LogSource | None" defaultValue="None" description="Filter by source: &#x27;stdout&#x27;, &#x27;stderr&#x27;, or &#x27;system&#x27;." />
<Parameter name="search_text" type="str" defaultValue="&quot;&quot;" description="Filter by search text." />

**Yields**

`LogEntry` objects in chronological order.

**Usage**

```python notest
sandbox = modal.Sandbox.from_name("my-app", "sandbox")

for entry in sandbox.logs.fetch(
    since=datetime.now() - timedelta(minutes=25),
    source="stdout",
):
    print(entry.message, end="")
```

### logs.tail

```python
tail(self, entries=100, *, source=None)
```
Fetch the most recent Sandbox logs.

**Parameters**

<Parameter name="entries" type="int" defaultValue="100" description="The number of log entries to return." />
<Parameter name="source" type="LogSource | None" defaultValue="None" description="Filter by source: &#x27;stdout&#x27;, &#x27;stderr&#x27;, or &#x27;system&#x27;." />

**Yields**

`LogEntry` objects in chronological order.
