# SandboxSnapshot


```python
class SandboxSnapshot(modal.object.Object)
```

> Sandbox memory snapshots are in **early preview**.

A `SandboxSnapshot` object lets you interact with a stored Sandbox snapshot that was created by calling
`._experimental_snapshot()` on a Sandbox instance. This includes both the filesystem and memory state of
the original Sandbox at the time the snapshot was taken.


## hydrate

```python
hydrate(self, client=None)
```
Synchronize the local object with its identity on the Modal server.

It is rarely necessary to call this method explicitly, as most operations
will lazily hydrate when needed. The main use case is when you need to
access object metadata, such as its ID.

*Added in v0.72.39*: This method replaces the deprecated `.resolve()` method.

## from_id

```python
from_id(cls, sandbox_snapshot_id, client=None)
```
Construct a `SandboxSnapshot` for an existing snapshot ID.

**Parameters**

<Parameter name="sandbox_snapshot_id" type="str" description="Snapshot ID returned when the snapshot was created." />
<Parameter name="client" type="&quot;modal.client.Client | None&quot;" defaultValue="None" description="Modal client to use; defaults to `Client.from_env()` when omitted." />

**Returns**

A `SandboxSnapshot` handle (hydration validates the ID when used).
