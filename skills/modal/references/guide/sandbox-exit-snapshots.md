# Sandbox Exit Snapshots

<Callout variant="beta">

Exit snapshots do not guarantee that a Sandbox's filesystem will be persisted in cases of rare hardware failures. If you need stronger durability guarantees, consider using [Volumes](/docs/guide/volumes).

</Callout>

Exit Snapshots take a [filesystem snapshot](/docs/guide/sandbox-snapshots#filesystem-snapshots)
automatically on both graceful and ungraceful Sandbox exits, including
`terminate()`, entrypoint completion, idle timeout, lifetime expiry, and OOM.

This is useful when you want filesystem state after a Sandbox is gone without
having to snapshot the filesystem yourself first. Typical uses:

* Resuming an agent or coding session after an idle timeout
* Recovering work from a Sandbox that exited unexpectedly
* Avoiding races between your own teardown and an in-flight manual snapshot

## Usage

Opt in at time of creation by setting `enable_exit_snapshot` in the
experimental options, then fetch the resulting [Image](/docs/guide/images)
after the Sandbox has exited:

<CodeTabs>
  {#snippet python()}

```python notest
import modal

app = modal.App.lookup("exit-snapshot-example", create_if_missing=True)

sb = modal.Sandbox.create(
    "bash",
    "-c",
    "echo hello > /tmp/marker.txt",
    app=app,
    experimental_options={"enable_exit_snapshot": True},
)
sb.wait()

image = sb._experimental_get_exit_snapshot()
restored = modal.Sandbox.create(app=app, image=image)
print(restored.filesystem.read_text("/tmp/marker.txt"))  # "hello\n"
restored.terminate()
```

{/snippet}
{#snippet javascript()}

```javascript notest
import { ModalClient } from "modal";

const modal = new ModalClient();
const app = await modal.apps.fromName("exit-snapshot-example", {
  createIfMissing: true,
});
const image = modal.images.fromRegistry("python:3.13-slim");

const sb = await modal.sandboxes.create(app, image, {
  command: ["bash", "-c", "echo hello > /tmp/marker.txt"],
  experimentalOptions: { enable_exit_snapshot: true },
});
await sb.wait();

const snapshot = await sb.experimentalGetExitSnapshot();
const restored = await modal.sandboxes.create(app, snapshot);
console.log(await restored.filesystem.readText("/tmp/marker.txt")); // "hello"
await restored.terminate();
```

{/snippet}
{#snippet go()}

```go notest
package main

import (
	"context"
	"fmt"

	modal "github.com/modal-labs/modal-client/go"
)

func main() {
	ctx := context.Background()
	mc, _ := modal.NewClient()

	app, _ := mc.Apps.FromName(ctx, "exit-snapshot-example", &modal.AppFromNameParams{
		CreateIfMissing: true,
	})
	image := mc.Images.FromRegistry("python:3.13-slim", nil)

	sb, _ := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
		Command:             []string{"bash", "-c", "echo hello > /tmp/marker.txt"},
		ExperimentalOptions: map[string]any{"enable_exit_snapshot": true},
	})
	sb.Wait(ctx, nil)

	snapshot, _ := sb.ExperimentalGetExitSnapshot(ctx, nil)
	restored, _ := mc.Sandboxes.Create(ctx, app, snapshot, nil)
	text, _ := restored.Filesystem.ReadText(ctx, "/tmp/marker.txt", nil)
	fmt.Println(text) // "hello"
	restored.Terminate(ctx, nil)
}
```

{/snippet} </CodeTabs>

You can also reconnect to the Sandbox later by ID and fetch the exit snapshot
from that handle. This is useful when the create and resume happen in
different processes:

<CodeTabs>
  {#snippet python()}

```python notest
import modal

app = modal.App.lookup("exit-snapshot-example", create_if_missing=True)

# Process A: create a Sandbox, do work, then let it idle out or terminate.
sb = modal.Sandbox.create(
    app=app,
    experimental_options={"enable_exit_snapshot": True},
)
sb.filesystem.write_text("session state", "/workspace/state.txt")
sandbox_id = sb.object_id
sb.terminate(wait=True)

# Process B: resume from the exit snapshot.
sb = modal.Sandbox.from_id(sandbox_id)
image = sb._experimental_get_exit_snapshot()
sb2 = modal.Sandbox.create(app=app, image=image)
print(sb2.filesystem.read_text("/workspace/state.txt"))  # "session state"
sb2.terminate()
```

{/snippet}
{#snippet javascript()}

```javascript notest
// Process A: create a Sandbox, do work, then let it idle out or terminate.
const sb = await modal.sandboxes.create(app, image, {
  experimentalOptions: { enable_exit_snapshot: true },
});
await sb.filesystem.writeText("session state", "/workspace/state.txt");
const sandboxId = sb.sandboxId;
await sb.terminate({ wait: true });

// Process B: resume from the exit snapshot.
const sb1 = await modal.sandboxes.fromId(sandboxId);
const snapshot = await sb1.experimentalGetExitSnapshot();
const sb2 = await modal.sandboxes.create(app, snapshot);
console.log(await sb2.filesystem.readText("/workspace/state.txt")); // "session state"
await sb2.terminate();
```

{/snippet}
{#snippet go()}

```go notest
// Process A: create a Sandbox, do work, then let it idle out or terminate.
sb, _ := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	ExperimentalOptions: map[string]any{"enable_exit_snapshot": true},
})
sb.Filesystem.WriteText(ctx, "session state", "/workspace/state.txt", nil)
sandboxID := sb.SandboxID
sb.Terminate(ctx, &modal.SandboxTerminateParams{Wait: true})

// Process B: resume from the exit snapshot.
sb, _ = mc.Sandboxes.FromID(ctx, sandboxID, nil)
snapshot, _ := sb.ExperimentalGetExitSnapshot(ctx, nil)
sb2, _ := mc.Sandboxes.Create(ctx, app, snapshot, nil)
text, _ := sb2.Filesystem.ReadText(ctx, "/workspace/state.txt", nil)
fmt.Println(text) // "session state"
sb2.Terminate(ctx, nil)
```

{/snippet} </CodeTabs>

## Waiting for the snapshot

Fetching the exit snapshot long-polls until the snapshot reaches a terminal
state. The timeout parameter controls how long to wait:

| Timeout         | Behavior                                              |
| --------------- | ----------------------------------------------------- |
| Unset (default) | Wait until the snapshot succeeds or fails             |
| `0`             | Immediate check; fails with `TimeoutError` if pending |
| `> 0`           | Wait up to the specified duration                     |

On success, the method returns an `Image` you can use to create a new
Sandbox.

## Errors

Fetching the exit snapshot can fail with these errors:

| Error                   | When                                                                       |
| ----------------------- | -------------------------------------------------------------------------- |
| `SnapshotCreationError` | Snapshot creation failed                                                   |
| `TimeoutError`          | Still pending when your timeout elapses                                    |
| `InvalidError`          | Exit snapshots were not enabled on the Sandbox, or the timeout is negative |
| `NotFoundError`         | The Sandbox no longer exists                                               |

In Python these are all `modal.exception` classes. Note that `TimeoutError` is
Modal's own class rather than Python's builtin, so a bare `except TimeoutError`
will not catch it.

## Retention

Exit snapshot Images are retained for 30 days after creation, matching the
default for [filesystem snapshots](/docs/guide/sandbox-snapshots#snapshot-retention).
After that, attempting to use the Image fails with `NotFoundError`.

## Limitations

* **Filesystem only.** Exit Snapshots capture the Sandbox filesystem, not
  memory or directory mounts.
* **Main container only.** [Sidecar containers](/docs/guide/sandbox-sidecars)
  are not included.
* **Preemption is not covered.** GPU Sandboxes [may run on preemptible
  capacity](/docs/guide/sandbox-resources#gpu-sandboxes), and a preempted
  host generally does not give the Sandbox enough time to take an exit
  snapshot. This only affects GPU Sandboxes - CPU Sandboxes are not
  preemptible. If you rely on exit snapshots for GPU Sandboxes, also
  [snapshot the filesystem](/docs/guide/sandbox-snapshots#filesystem-snapshots)
  periodically.
* **Snapshot failure loses that Sandbox's filesystem state.** If you need to
  periodically persist state with stronger durability guarantees, prefer
  [Volumes](/docs/guide/volumes).
