# Snapshots

Sandboxes support snapshotting, allowing you to save your Sandbox's state
and restore it later. This is useful for:

* Reducing startup latency
* Creating custom environments for your Sandboxes to run in
* Backing up your Sandbox's state for debugging
* Running large-scale experiments with the same initial state
* Branching your Sandbox's state to test different code changes independently

Modal currently supports three different kinds of Sandbox snapshots:

1. [Filesystem Snapshots](#filesystem-snapshots)
2. [Directory Snapshots](#directory-snapshots)
3. [Memory Snapshots](#memory-snapshots)

## Snapshot Retention

Different snapshot types have different retention policies:

| Snapshot Type       | Default Retention Period |
| ------------------- | ------------------------ |
| Filesystem Snapshot | 30 days after creation   |
| Directory Snapshot  | 30 days after creation   |
| Memory Snapshot     | 7 days after creation    |

<Callout variant="warning">

**Breaking change in v1.5 (Python) / v0.8.0 (Go/JS):** Filesystem Snapshots now default to a 30-day TTL. Previously, Filesystem Snapshots persisted indefinitely and Directory Snapshots already defaulted to 30 days. Both `snapshot_filesystem()` and `snapshot_directory()` now accept an explicit TTL parameter that you can use to override the default, including opting out of expiry entirely.

</Callout>

Filesystem Snapshots and Directory Snapshots are [Images](/docs/sdk/py/latest/Image) and are automatically garbage collected after their TTL expires (30 days by default). You can configure a custom TTL when creating a snapshot, or opt out of expiry entirely to retain snapshots indefinitely. Memory Snapshots expire 7 days after creation and cannot currently be extended.

Here is how to configure custom TTLs for each snapshot type:

<CodeTabs>
  {#snippet python()}

```python notest
# Filesystem snapshot with custom TTL of 7 days
image = sb.snapshot_filesystem(ttl=7 * 24 * 3600)

# Filesystem snapshot with no expiry (retain indefinitely, like the pre-v1.5 default)
image = sb.snapshot_filesystem(ttl=None)

# Directory snapshot with custom TTL of 7 days
snapshot = sb.snapshot_directory("/project", ttl=7 * 24 * 3600)

# Directory snapshot with no expiry
snapshot = sb.snapshot_directory("/project", ttl=None)
```

{/snippet}
{#snippet javascript()}

```javascript notest
import { ModalClient } from "modal";

const modal = new ModalClient();
const app = await modal.apps.fromName("sandbox-snapshots", {
  createIfMissing: true,
});
const baseImage = modal.images.fromRegistry("python:3.13-slim");
const sb = await modal.sandboxes.create(app, baseImage);
await (await sb.exec(["mkdir", "-p", "/project"])).wait();

// Filesystem snapshot with custom TTL of 7 days
let image = await sb.snapshotFilesystem({ ttlMs: 7 * 24 * 3600 * 1000 });

// Filesystem snapshot with no expiry (retain indefinitely, like the pre-v0.8.0 default)
image = await sb.snapshotFilesystem({ ttlMs: null });

// Directory snapshot with custom TTL of 7 days
let snapshot = await sb.snapshotDirectory("/project", {
  ttlMs: 7 * 24 * 3600 * 1000,
});

// Directory snapshot with no expiry
snapshot = await sb.snapshotDirectory("/project", { ttlMs: null });
await sb.terminate();
```

{/snippet}
{#snippet go()}

```go notest
package main

import (
	"context"
	"fmt"
	"time"

	modal "github.com/modal-labs/modal-client/go"
)

func main() {
	ctx := context.Background()
	mc, _ := modal.NewClient()
	app, _ := mc.Apps.FromName(ctx, "sandbox-snapshots", &modal.AppFromNameParams{
		CreateIfMissing: true,
	})
	baseImage := mc.Images.FromRegistry("python:3.13-slim", nil)
	sb, _ := mc.Sandboxes.Create(ctx, app, baseImage, nil)
	p, _ := sb.Exec(ctx, []string{"mkdir", "-p", "/project"}, nil)
	p.Wait(ctx, nil)

	// Filesystem snapshot with custom TTL of 7 days
	image, _ := sb.SnapshotFilesystem(ctx, &modal.SandboxSnapshotFilesystemParams{
		TTL: 7 * 24 * time.Hour,
	})
	fmt.Println(image.ImageID)

	// Filesystem snapshot with no expiry (retain indefinitely, like the pre-v0.8.0 default)
	image, _ = sb.SnapshotFilesystem(ctx, &modal.SandboxSnapshotFilesystemParams{
		TTL: modal.NoExpiryTTL,
	})
	fmt.Println(image.ImageID)

	// Directory snapshot with custom TTL of 7 days
	snapshot, _ := sb.SnapshotDirectory(ctx, "/project", &modal.SandboxSnapshotDirectoryParams{
		TTL: 7 * 24 * time.Hour,
	})
	fmt.Println(snapshot.ImageID)

	// Directory snapshot with no expiry
	snapshot, _ = sb.SnapshotDirectory(ctx, "/project", &modal.SandboxSnapshotDirectoryParams{
		TTL: modal.NoExpiryTTL,
	})
	fmt.Println(snapshot.ImageID)
	sb.Terminate(ctx, nil)
}
```

{/snippet} </CodeTabs>

If you try to use an expired snapshot, Modal will raise a `NotFoundError` — immediately when mounting the Image into a running Sandbox, or upon first interaction (e.g. `exec` or `wait`) when starting a new Sandbox from the expired Image. Referencing an Image by ID is lazy and will not raise an error on construction even if the provided Image ID has been deleted.

To manage storage for long-lived snapshots, you can delete them programmatically when no longer needed. See [Deleting Snapshots](#deleting-snapshots) for details.

## Filesystem Snapshots

Filesystem Snapshots are copies of the Sandbox's root filesystem at a given point in time.
These Snapshots are [Images](/docs/sdk/py/latest/Image) and can be used to create new Sandboxes.

Snapshot a running Sandbox's filesystem, then start a new Sandbox from the resulting Image:

<CodeTabs>
  {#snippet python()}

```python notest
import modal

app = modal.App.lookup("sandbox-fs-snapshot-test", create_if_missing=True)

sb = modal.Sandbox.create(app=app)
p = sb.exec("bash", "-c", "echo 'test' > /test")
p.wait()
assert p.returncode == 0, "failed to write to file"
image = sb.snapshot_filesystem()
sb.terminate()

sb2 = modal.Sandbox.create(image=image, app=app)
p2 = sb2.exec("bash", "-c", "cat /test")
assert p2.stdout.read().strip() == "test"
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image);
const p = await sb.exec(["bash", "-c", "echo 'test' > /test"]);
await p.wait();
const snapshotImage = await sb.snapshotFilesystem();
await sb.terminate();

const sb2 = await modal.sandboxes.create(app, snapshotImage);
const p2 = await sb2.exec(["bash", "-c", "cat /test"], { stdout: "pipe" });
console.assert((await p2.stdout.readText()).trim() === "test");
await sb2.terminate();
```

{/snippet}

{#snippet go()}

```go notest
sb, _ := mc.Sandboxes.Create(ctx, app, image, nil)
p, _ := sb.Exec(ctx, []string{"bash", "-c", "echo 'test' > /test"}, nil)
p.Wait(ctx, nil)
snapshotImage, _ := sb.SnapshotFilesystem(ctx, nil)
sb.Terminate(ctx, nil)

sb2, _ := mc.Sandboxes.Create(ctx, app, snapshotImage, nil)
p2, _ := sb2.Exec(ctx, []string{"bash", "-c", "cat /test"}, &modal.SandboxExecParams{
	Stdout: modal.Pipe,
})
stdout, _ := io.ReadAll(p2.Stdout)
fmt.Println(strings.TrimSpace(string(stdout)))
sb2.Terminate(ctx, nil)
```

{/snippet} </CodeTabs>

Filesystem Snapshots are optimized for performance: they are calculated as the difference
from your base image, so only modified files are stored. Restoring a Filesystem Snapshot
utilizes the same infrastructure we use to get fast cold starts for your Sandboxes.

See [Snapshot Retention](#snapshot-retention) for TTL configuration options and [Deleting Snapshots](#deleting-snapshots) to learn how to manage snapshot storage.

Note that a Filesystem Snapshot only covers the Sandbox's root filesystem.
Any mounted [Volumes](/docs/guide/volumes) are not covered by this Snapshot
and will not be included in the resulting Image.

### Forking

Since Filesystem Snapshots are [Images](/docs/sdk/py/latest/modal.Image), you can create multiple Sandboxes from the same snapshot. Each Sandbox starts with an identical copy of the snapshotted filesystem, so you can use this to run parallel workloads or test different changes independently.

<CodeTabs>
  {#snippet python()}

```python notest
import modal

app = modal.App.lookup("sandbox-fork-example", create_if_missing=True)

sb = modal.Sandbox.create(app=app)
p = sb.exec("bash", "-c", "pip install numpy && echo 'setup done' > /status")
p.wait()

image = sb.snapshot_filesystem()
sb.terminate()

# Start multiple Sandboxes from the same snapshot
sb2 = modal.Sandbox.create(image=image, app=app)
sb3 = modal.Sandbox.create(image=image, app=app)

# Each fork starts from the snapshotted state
assert sb2.exec("cat", "/status").stdout.read().strip() == "setup done"
assert sb3.exec("cat", "/status").stdout.read().strip() == "setup done"
```

{/snippet}
{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image);
const p = await sb.exec([
  "bash",
  "-c",
  "pip install numpy && echo 'setup done' > /status",
]);
await p.wait();

const snapshot = await sb.snapshotFilesystem();
await sb.terminate();

// Start multiple Sandboxes from the same snapshot
const sb2 = await modal.sandboxes.create(app, snapshot);
const sb3 = await modal.sandboxes.create(app, snapshot);

// Each fork starts from the snapshotted state
const p2 = await sb2.exec(["cat", "/status"]);
console.assert((await p2.stdout.readText()).trim() === "setup done");
const p3 = await sb3.exec(["cat", "/status"]);
console.assert((await p3.stdout.readText()).trim() === "setup done");
```

{/snippet}
{#snippet go()}

```go notest
sb, _ := mc.Sandboxes.Create(ctx, app, image, nil)
p, _ := sb.Exec(ctx, []string{"bash", "-c", "pip install numpy && echo 'setup done' > /status"}, nil)
p.Wait(ctx, nil)

snapshot, _ := sb.SnapshotFilesystem(ctx, nil)
sb.Terminate(ctx, nil)

// Start multiple Sandboxes from the same snapshot
sb2, _ := mc.Sandboxes.Create(ctx, app, snapshot, nil)
sb3, _ := mc.Sandboxes.Create(ctx, app, snapshot, nil)

// Each fork starts from the snapshotted state
p2, _ := sb2.Exec(ctx, []string{"cat", "/status"}, nil)
stdout2, _ := io.ReadAll(p2.Stdout)
fmt.Println(strings.TrimSpace(string(stdout2))) // "setup done"

p3, _ := sb3.Exec(ctx, []string{"cat", "/status"}, nil)
stdout3, _ := io.ReadAll(p3.Stdout)
fmt.Println(strings.TrimSpace(string(stdout3))) // "setup done"
```

{/snippet} </CodeTabs>

## Directory Snapshots

Directory Snapshots allow you to snapshot a specific directory within a running Sandbox. The resulting snapshot is an Image that can then be mounted into another already-running Sandbox (typically at a later time), which can be useful for:

* **Updating system dependencies separately from application code**: Base dependencies can be updated by starting a new Sandbox from an updated base Image, and then mounting in previously snapshotted application code.
* **Using warm pools in combination with snapshots**: For use cases that benefit from a [warm pool](/docs/examples/sandbox_pool) of Sandboxes to reduce start-up latency, the first initialization can now happen in the warm pool without losing the ability to restore application-specific code at a later point in time.
* **Speeding up resumptions of previous sessions**: Files in mounted Images are prioritized when containers load files, so mounting a directory can speed up Sandbox resumptions vs. starting from a full file system image.

### Usage

Use `snapshot_directory` to snapshot a directory,
`mount_image` to mount a previous directory snapshot at a directory path,
and `unmount_image` to remove that mounted Image later.
To protect directory snapshots with customer-held key material, see
[Customer Supplied Encryption Keys](/docs/guide/customer-supplied-encryption-keys#directory-snapshots).

<CodeTabs>
  {#snippet python()}

```python notest
sb = modal.Sandbox.create(app=app)
# Write some dummy data
sb.exec("bash", "-c", "mkdir /project && echo 'data' > /project/file.txt").wait()

# Snapshot the directory
snapshot = sb.snapshot_directory("/project")

# Ok to throw away the old Sandbox at this point
sb.terminate()

# Mount the snapshot in a new Sandbox
sb2 = modal.Sandbox.create(app=app)
try:
    sb2.mount_image("/project", snapshot)
except modal.exception.NotFoundError:
    # Handle a potential ttl expiry of the old snapshot here
    ...

# The Sandbox now has access to the previous project state
assert sb2.exec("cat", "/project/file.txt").stdout.read().strip() == "data"

```

{/snippet}
{#snippet javascript()}

```javascript notest
import { NotFoundError } from "modal";

const sb = await modal.sandboxes.create(app, image);
// Write some dummy data
const p = await sb.exec([
  "bash",
  "-c",
  "mkdir /project && echo 'data' > /project/file.txt",
]);
await p.wait();

// Snapshot the directory
const snapshot = await sb.snapshotDirectory("/project");

// Ok to throw away the old Sandbox at this point
await sb.terminate();

// Mount the snapshot in a new Sandbox
const sb2 = await modal.sandboxes.create(app, image);
try {
  await sb2.mountImage("/project", snapshot);
} catch (e) {
  if (e instanceof NotFoundError) {
    // Handle a potential ttl expiry of the old snapshot here
  }
}

// The Sandbox now has access to the previous project state
const p2 = await sb2.exec(["cat", "/project/file.txt"]);
console.assert((await p2.stdout.readText()).trim() === "data");
```

{/snippet}
{#snippet go()}

```go notest
sb, _ := mc.Sandboxes.Create(ctx, app, image, nil)

// Write some dummy data
p, _ := sb.Exec(ctx, []string{"bash", "-c", "mkdir /project && echo 'data' > /project/file.txt"}, nil)
p.Wait(ctx, nil)

// Snapshot the directory
snapshot, _ := sb.SnapshotDirectory(ctx, "/project", nil)

// Ok to throw away the old Sandbox at this point
sb.Terminate(ctx, nil)

// Mount the snapshot in a new Sandbox
sb2, _ := mc.Sandboxes.Create(ctx, app, image, nil)

if err := sb2.MountImage(ctx, "/project", snapshot, nil); err != nil {
  var notFound modal.NotFoundError
  if errors.As(err, &notFound) {
    // Handle a potential ttl expiry of the old snapshot here
  }
}

// The Sandbox now has access to the previous project state
p2, _ := sb2.Exec(ctx, []string{"cat", "/project/file.txt"}, nil)
stdout, _ := io.ReadAll(p2.Stdout)
fmt.Println(strings.TrimSpace(string(stdout))) // "data"
```

{/snippet} </CodeTabs>

### Unmounting a mounted Image

To unmount a previously mounted Image,
call `unmount_image` on the exact path you passed to `mount_image`.
After unmounting, the underlying Sandbox filesystem at that path becomes visible again.

<CodeTabs>
  {#snippet python()}

```python notest
sb2.unmount_image("/project")
```

{/snippet}
{#snippet javascript()}

```javascript notest
await sb2.unmountImage("/project");
```

{/snippet}
{#snippet go()}

```go notest
_ = sb2.UnmountImage(ctx, "/project", nil)
```

{/snippet} </CodeTabs>

## Memory Snapshots

<Callout variant="alpha">

A number of known [limitations](#limitations) currently apply.

</Callout>

Sandbox memory snapshots are copies of a Sandbox’s entire state, both in memory and on the filesystem. These Snapshots can be restored later to create a new Sandbox, which is an exact clone of the original Sandbox.

Memory snapshots are supported on both [runtimes](/docs/guide/sandboxes#runtimes), and we recommend using memory snapshots with `runtime="vm"`.

To take a memory snapshot, create a Sandbox with memory snapshots enabled, then call its experimental snapshot method, which returns a `SandboxSnapshot`:

<CodeTabs>
  {#snippet python()}

```python notest
app = modal.App.lookup("sandbox-snapshot", create_if_missing=True)

# The named Image was built and published ahead of time with `curl` and `procps`
# installed, which the checks below rely on:
#
#     modal.Image.debian_slim().apt_install("curl", "procps").build(app).publish("sandbox-snapshot-base")

sb = modal.Sandbox.create(
    "python3", "-m", "http.server", "8000",
    app=app,
    # prefer named Images in Sandboxes to ensure they are never built during Sandbox launch
    image=modal.Image.from_name("sandbox-snapshot-base"),
    runtime="vm",
    _experimental_enable_snapshot=True,
)

print(f"Performing snapshot of {sb.object_id} ...")
snapshot = sb._experimental_snapshot()
```

{/snippet}

{#snippet javascript()}

```javascript notest
const snapshotImage = modal.images
  .fromRegistry("python:3.13-slim")
  .dockerfileCommands(["RUN apt-get update && apt-get install -y curl procps"]);

const sb = await modal.sandboxes.create(app, snapshotImage, {
  command: ["python3", "-m", "http.server", "8000"],
  runtime: "vm",
  experimentalEnableSnapshot: true,
});
console.log(`Performing snapshot of ${sb.sandboxId} ...`);
const snapshot = await sb.experimentalSnapshot();
```

{/snippet}

{#snippet go()}

```go notest
snapshotImage := mc.Images.FromRegistry("python:3.13-slim", nil).DockerfileCommands([]string{
	"RUN apt-get update && apt-get install -y curl procps",
}, nil)

sb, _ := mc.Sandboxes.Create(ctx, app, snapshotImage, &modal.SandboxCreateParams{
	Command:                    []string{"python3", "-m", "http.server", "8000"},
	Runtime:                    modal.SandboxRuntimeVM,
	ExperimentalEnableSnapshot: true,
})
fmt.Printf("Performing snapshot of %s ...\n", sb.SandboxID)
snapshot, _ := sb.ExperimentalSnapshot(ctx, nil)
fmt.Printf("Snapshot ID: %s\n", snapshot.SnapshotID)
```

{/snippet} </CodeTabs>

Create a new Sandbox from the returned `SandboxSnapshot`:

<CodeTabs>
  {#snippet python()}

```python notest
print(f"Restoring from snapshot {sb.object_id} ...")
sb2 = modal.Sandbox._experimental_from_snapshot(snapshot)

print("Let's see that the http.server is still running...")
p = sb2.exec("ps", "aux")
print(p.stdout.read())

# Talk to snapshotted Sandbox http.server
p = sb2.exec("curl", "http://localhost:8000/")
reply = p.stdout.read()
print(reply)  # <!DOCTYPE HTML><html lang...
```

{/snippet}

{#snippet javascript()}

```javascript notest
console.log(`Restoring from snapshot ${snapshot.snapshotId} ...`);
const sb2 = await modal.sandboxes.experimentalFromSnapshot(snapshot);

console.log("Let's see that the http.server is still running...");
let p = await sb2.exec(["ps", "aux"], { stdout: "pipe" });
console.log(await p.stdout.readText());

// Talk to snapshotted Sandbox http.server
p = await sb2.exec(["curl", "http://localhost:8000/"], { stdout: "pipe" });
console.log(await p.stdout.readText());
await sb2.terminate();
```

{/snippet}

{#snippet go()}

```go notest
fmt.Printf("Restoring from snapshot %s ...\n", snapshot.SnapshotID)
sb2, _ := mc.Sandboxes.ExperimentalFromSnapshot(ctx, snapshot, nil)

fmt.Println("Let's see that the http.server is still running...")
p, _ := sb2.Exec(ctx, []string{"ps", "aux"}, &modal.SandboxExecParams{
	Stdout: modal.Pipe,
})
stdout, _ := io.ReadAll(p.Stdout)
fmt.Print(string(stdout))

// Talk to snapshotted Sandbox http.server
p, _ = sb2.Exec(ctx, []string{"curl", "http://localhost:8000/"}, &modal.SandboxExecParams{
	Stdout: modal.Pipe,
})
stdout, _ = io.ReadAll(p.Stdout)
fmt.Print(string(stdout))
sb2.Terminate(ctx, nil)
```

{/snippet} </CodeTabs>

The new Sandbox will be a duplicate of your original Sandbox. All running processes will still be running, in the same state as when they were snapshotted, and any changes made to the filesystem will be visible.

To restore from a Snapshot later, save its ID. Then look up the Snapshot by that ID and restore from it:

<CodeTabs>
  {#snippet python()}

```python notest
snapshot_id = snapshot.object_id
# ... save the Sandbox ID (sb-123abc) for later
# sometime in the future...
snapshot = modal.SandboxSnapshot.from_id(snapshot_id)
sandbox = modal.Sandbox._experimental_from_snapshot(snapshot)
```

{/snippet}

{#snippet javascript()}

```javascript notest
const snapshotId = snapshot.snapshotId;
// ... save the snapshot ID for later
// sometime in the future...
const savedSnapshot = await modal.sandboxSnapshots.fromId(snapshotId);
const sandbox = await modal.sandboxes.experimentalFromSnapshot(savedSnapshot);
```

{/snippet}

{#snippet go()}

```go notest
snapshotID := snapshot.SnapshotID
// ... save the snapshot ID for later
// sometime in the future...
savedSnapshot, _ := mc.SandboxSnapshots.FromID(ctx, snapshotID, nil)
sandbox, _ := mc.Sandboxes.ExperimentalFromSnapshot(ctx, savedSnapshot, nil)
```

{/snippet} </CodeTabs>

Note that these methods are *experimental*, and we may change them in the future.

### Re-snapshotting

When creating a new memory snapshot from a Sandbox that was *itself* created from a memory snapshot, the new snapshot inherits the expiration date of the original snapshot.
This means a "chain" of snapshotted state can only ever become as old as the expiration date of the first snapshot in the series.

For example, snapshot\_2 in the following example would only be valid for 3 days after creation:

<CodeTabs>
  {#snippet python()}

```python notest
sandbox_1 = modal.Sandbox.create(runtime="vm", _experimental_enable_snapshot=True)

# snapshot_1 has a lifetime of 7 days from creation
snapshot_1 = sandbox_1._experimental_snapshot()

# 4 days later we do a restore + snapshot from snapshot_1
print(f"Restoring from snapshot {snapshot_1.object_id} ...")
sandbox_2 = modal.Sandbox._experimental_from_snapshot(snapshot_1)
snapshot_2 = sandbox_2._experimental_snapshot()
# snapshot_2 now has a lifetime of 7 - 4 = 3 days from creation
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sandbox1 = await modal.sandboxes.create(app, image, {
  runtime: "vm",
  experimentalEnableSnapshot: true,
});
// snapshot1 has a lifetime of 7 days from creation
const snapshot1 = await sandbox1.experimentalSnapshot();

// 4 days later, restore and snapshot again
console.log(`Restoring from snapshot ${snapshot1.snapshotId} ...`);
const sandbox2 = await modal.sandboxes.experimentalFromSnapshot(snapshot1);
const snapshot2 = await sandbox2.experimentalSnapshot();
// The new snapshot now has a lifetime of 7 - 4 = 3 days from creation
```

{/snippet}

{#snippet go()}

```go notest
sandbox1, _ := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Runtime:                    modal.SandboxRuntimeVM,
	ExperimentalEnableSnapshot: true,
})
// snapshot1 has a lifetime of 7 days from creation
snapshot1, _ := sandbox1.ExperimentalSnapshot(ctx, nil)

// 4 days later, restore and snapshot again
fmt.Printf("Restoring from snapshot %s ...\n", snapshot1.SnapshotID)
sandbox2, _ := mc.Sandboxes.ExperimentalFromSnapshot(ctx, snapshot1, nil)
snapshot2, _ := sandbox2.ExperimentalSnapshot(ctx, nil)
// snapshot2 now has a lifetime of 7 - 4 = 3 days from creation
```

{/snippet} </CodeTabs>

### Limitations

* Sandbox Memory Snapshots expire 7 days after creation (see [Snapshot Retention](#snapshot-retention)). For longer persisting snapshots, try [Filesystem Snapshots](#filesystem-snapshots).
* Open TCP connections will be closed automatically when a Snapshot is taken, and will need to be reopened when the Snapshot is restored.
* Snapshotting a Sandbox will currently cause it to terminate. We intend to remove this limitation soon.
* Sandboxes created with memory snapshots enabled or restored from Snapshots cannot run with GPUs.
* It is not possible to snapshot a Sandbox while an exec command is still running. Furthermore, any background processes launched by an exec call will not be properly restored after a snapshot.
* A Sandbox created with memory snapshots enabled can only be restored on the same exact instance type that the original Sandbox was run on. Given Modal's diverse fleet of capacity, this can sometimes lead to scheduling delays.
* A Sandbox created with memory snapshots enabled cannot pin its region, and a Sandbox restored from a Memory Snapshot is scheduled wherever the original instance type is available.

## Persisting Sandbox State

To persist state across Sandbox sessions, you need to:

1. **Trigger the snapshot.** Snapshots are triggered from outside the Sandbox, typically just before termination. A common pattern is to run an exec process inside the Sandbox and wait for it to exit. Once it does, the controller takes a snapshot and terminates the Sandbox.
2. **Store the snapshot ID.** You need this ID to restore from the snapshot later. It is typically keyed by a session or user ID, and can be stored in your database, an external key-value store, or a [Modal Dict](/docs/guide/dicts).

The following example shows this pattern. This code would typically run in a Modal Function or your own backend, orchestrating the Sandbox:

<CodeTabs>
  {#snippet python()}

```python notest
import modal

app = modal.App.lookup("sandbox-snapshot-lifecycle", create_if_missing=True)
snapshot_store = modal.Dict.from_name("sandbox-snapshots", create_if_missing=True)
session_id = "sess_a1b2c3d4"

# Restore from snapshot, or use the base image
if session_id in snapshot_store:
    image = modal.Image.from_id(snapshot_store[session_id])
else:
    # prefer named Images in Sandboxes to ensure they are never built during Sandbox launch
    image = modal.Image.from_name("sandbox-session-base")

sb = modal.Sandbox.create(image=image, app=app)

# Run agent which exits when ready to be snapshotted
p = sb.exec("python", "agent.py")
p.wait()

# Snapshot and store the object_id
snapshot_store[session_id] = sb.snapshot_filesystem().object_id
sb.terminate()
```

{/snippet}

{#snippet javascript()}

```javascript notest
// Replace this in-process map with your database or key-value store.
const snapshotStore = new Map();
const sessionId = "sess_a1b2c3d4";

// Restore from snapshot, or use the base Image.
let restoredImage = image;
const snapshotId = snapshotStore.get(sessionId);
if (snapshotId) {
  restoredImage = await modal.images.fromId(snapshotId);
}

const sb = await modal.sandboxes.create(app, restoredImage);

// Run agent which exits when ready to be snapshotted.
const p = await sb.exec(["python", "agent.py"]);
await p.wait();

// Snapshot and store the Image ID.
const snapshot = await sb.snapshotFilesystem();
snapshotStore.set(sessionId, snapshot.imageId);
await sb.terminate();
```

{/snippet}

{#snippet go()}

```go notest
// Replace this in-process map with your database or key-value store.
snapshotStore := map[string]string{}
sessionID := "sess_a1b2c3d4"

// Restore from snapshot, or use the base Image.
restoredImage := image
if snapshotID, ok := snapshotStore[sessionID]; ok {
	restoredImage, _ = mc.Images.FromID(ctx, snapshotID, nil)
}

sb, _ := mc.Sandboxes.Create(ctx, app, restoredImage, nil)

// Run agent which exits when ready to be snapshotted.
p, _ := sb.Exec(ctx, []string{"python", "agent.py"}, nil)
p.Wait(ctx, nil)

// Snapshot and store the Image ID.
snapshot, _ := sb.SnapshotFilesystem(ctx, nil)
snapshotStore[sessionID] = snapshot.ImageID
sb.Terminate(ctx, nil)
```

{/snippet} </CodeTabs>

## Deleting Snapshots

Since both Filesystem and Directory Snapshots are [Images](/docs/sdk/py/latest/Image), you can delete them using the image deletion API. This is useful for managing storage or complying with data retention policies.

<Callout variant="warning">

Deletion is irreversible. Deleted snapshots cannot be recovered, and any Sandboxes configured to use a deleted snapshot will fail to start.

</Callout>

<CodeTabs>
  {#snippet python()}

```python notest
import modal.experimental

# Get the image ID from a filesystem or directory snapshot
image = sb.snapshot_filesystem()
# or: image = sb.snapshot_directory("/project")
image_id = image.object_id  # e.g., "im-abc123"

# Later, delete the snapshot when no longer needed
modal.experimental.image_delete(image_id)
```

{/snippet}
{#snippet javascript()}

```javascript notest
// Get the image ID from a filesystem or directory snapshot
const image = await sb.snapshotFilesystem();
// or: const image = await sb.snapshotDirectory("/project");
const imageId = image.imageId; // e.g., "im-abc123"

// Later, delete the snapshot when no longer needed
await modal.images.delete(imageId);
```

{/snippet}
{#snippet go()}

```go notest
// Get the image ID from a filesystem or directory snapshot
snapshotImage, _ := sb.SnapshotFilesystem(ctx, nil)
// or: snapshotImage, _ := sb.SnapshotDirectory(ctx, "/project", nil)
imageId := snapshotImage.ImageID // e.g., "im-abc123"

// Later, delete the snapshot when no longer needed
mc.Images.Delete(ctx, imageId, nil)
```

{/snippet} </CodeTabs>

To delete snapshots, you need to track the image IDs yourself (e.g., in a database or [Modal Dict](/docs/guide/dicts)), since there is currently no API to list all snapshots you have created.
