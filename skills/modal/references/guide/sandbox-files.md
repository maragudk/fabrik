# Filesystem Access

There are multiple options for uploading files to a Sandbox and accessing them
from outside the Sandbox.

## Filesystem API

The most convenient way to pass data in and out of the Sandbox during
execution is to use our filesystem API:

<CodeTabs>
  {#snippet python()}

```python
import modal

app = modal.App.lookup("sandbox-fs-demo", create_if_missing=True)

sb = modal.Sandbox.create(app=app)

# Write text to a file in the Sandbox.
sb.filesystem.write_text("Hello World!\n", "/tmp/test.txt")

# Read the file back from the Sandbox into a string.
contents = sb.filesystem.read_text("/tmp/test.txt")
print(contents)

sb.terminate()
```

{/snippet}
{#snippet javascript()}

```javascript notest
import { ModalClient } from "modal";

const modal = new ModalClient();
const app = await modal.apps.fromName("sandbox-fs-demo", {
  createIfMissing: true,
});
const image = modal.images.fromRegistry("python:3.13-slim");

const sb = await modal.sandboxes.create(app, image);

// Write text to a file in the Sandbox.
await sb.filesystem.writeText("Hello World!\n", "/tmp/test.txt");

// Read the file back from the Sandbox into a string.
const contents = await sb.filesystem.readText("/tmp/test.txt");
console.log(contents);

await sb.terminate();
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

	app, _ := mc.Apps.FromName(ctx, "sandbox-fs-demo", &modal.AppFromNameParams{
		CreateIfMissing: true,
	})
	image := mc.Images.FromRegistry("python:3.13-slim", nil)

	sb, _ := mc.Sandboxes.Create(ctx, app, image, nil)
	defer sb.Terminate(ctx, nil)

	fs := sb.Filesystem

	// Write text to a file in the Sandbox.
	fs.WriteText(ctx, "Hello World!\n", "/tmp/test.txt", nil)

	// Read the file back from the Sandbox into a string.
	contents, _ := fs.ReadText(ctx, "/tmp/test.txt", nil)
	fmt.Println(contents)
}
```

{/snippet} </CodeTabs>

It has convenience APIs for streaming file copies in both directions:

<CodeTabs>
  {#snippet python()}

```python
from pathlib import Path
import modal

# Write a local file.
with open("local-file.txt", "w") as f:
    f.write("Hello World!\n")

app = modal.App.lookup("sandbox-fs-demo", create_if_missing=True)

sb = modal.Sandbox.create(app=app)

# Copy the local file into the Sandbox.
sb.filesystem.copy_from_local("local-file.txt", "/tmp/file-in-sandbox.txt")

# Copy it back to the local filesystem.
sb.filesystem.copy_to_local("/tmp/file-in-sandbox.txt", "local-file-copy.txt")

print(Path("local-file-copy.txt").read_text())

sb.terminate()
```

{/snippet}
{#snippet javascript()}

```javascript notest
import { readFile, writeFile } from "node:fs/promises";

const sb = await modal.sandboxes.create(app, image);

// Write a local file.
await writeFile("local-file.txt", "Hello World!\n", "utf-8");

// Copy the local file into the Sandbox.
await sb.filesystem.copyFromLocal("local-file.txt", "/tmp/file-in-sandbox.txt");

// Copy it back to the local filesystem.
await sb.filesystem.copyToLocal(
  "/tmp/file-in-sandbox.txt",
  "local-file-copy.txt",
);

console.log(await readFile("local-file-copy.txt", "utf-8"));

await sb.terminate();
```

{/snippet}
{#snippet go()}

```go notest
sb, _ := mc.Sandboxes.Create(ctx, app, image, nil)
defer sb.Terminate(ctx, nil)

fs := sb.Filesystem

// Write a local file.
os.WriteFile("local-file.txt", []byte("Hello World!\n"), 0o644)

// Copy the local file into the Sandbox.
fs.CopyFromLocal(ctx, "local-file.txt", "/tmp/file-in-sandbox.txt", nil)

// Copy it back to the local filesystem.
fs.CopyToLocal(ctx, "/tmp/file-in-sandbox.txt", "local-file-copy.txt", nil)

data, _ := os.ReadFile("local-file-copy.txt")
fmt.Println(string(data))
```

{/snippet} </CodeTabs>

It also offers APIs for inspecting and managing files:

<CodeTabs>
  {#snippet python()}

```python
import modal

app = modal.App.lookup("sandbox-fs-demo", create_if_missing=True)

sb = modal.Sandbox.create(app=app)

# Set up a structured project.
sb.filesystem.make_directory("/tmp/project/results")

# Let the Sandbox do some work and write outputs to files.
sb.filesystem.write_text("42\n", "/tmp/project/results/answer.txt")
sb.filesystem.write_text("debug info\n", "/tmp/project/results/debug.log")

# Inspect what was produced.
for entry in sb.filesystem.list_files("/tmp/project/results"):
    print(entry.name, entry.type.value, entry.size)

# Check that the result file has content before downloading it.
info = sb.filesystem.stat("/tmp/project/results/answer.txt")
if info.size > 0:
    answer = sb.filesystem.read_text("/tmp/project/results/answer.txt")
    print(answer)

# Clean up the whole project.
sb.filesystem.remove("/tmp/project", recursive=True)

sb.terminate()
```

{/snippet}
{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image);

// Set up a structured project.
await sb.filesystem.makeDirectory("/tmp/project/results");

// Let the Sandbox do some work and write outputs to files.
await sb.filesystem.writeText("42\n", "/tmp/project/results/answer.txt");
await sb.filesystem.writeText("debug info\n", "/tmp/project/results/debug.log");

// Inspect what was produced.
const entries = await sb.filesystem.listFiles("/tmp/project/results");
for (const entry of entries) {
  console.log(entry.name, entry.type, entry.size);
}

// Check that the result file has content before downloading it.
const info = await sb.filesystem.stat("/tmp/project/results/answer.txt");
if (info.size > 0) {
  const answer = await sb.filesystem.readText(
    "/tmp/project/results/answer.txt",
  );
  console.log(answer);
}

// Clean up the whole project.
await sb.filesystem.remove("/tmp/project", { recursive: true });

await sb.terminate();
```

{/snippet}
{#snippet go()}

```go notest
sb, _ := mc.Sandboxes.Create(ctx, app, image, nil)
defer sb.Terminate(ctx, nil)

fs := sb.Filesystem

// Set up a structured project.
fs.MakeDirectory(ctx, "/tmp/project/results", nil)

// Let the Sandbox do some work and write outputs to files.
fs.WriteText(ctx, "42\n", "/tmp/project/results/answer.txt", nil)
fs.WriteText(ctx, "debug info\n", "/tmp/project/results/debug.log", nil)

// Inspect what was produced.
entries, _ := fs.ListFiles(ctx, "/tmp/project/results", nil)
for _, entry := range entries {
	fmt.Println(entry.Name, entry.Type, entry.Size)
}

// Check that the result file has content before downloading it.
info, _ := fs.Stat(ctx, "/tmp/project/results/answer.txt", nil)
if info.Size > 0 {
	answer, _ := fs.ReadText(ctx, "/tmp/project/results/answer.txt", nil)
	fmt.Println(answer)
}

// Clean up the whole project.
fs.Remove(ctx, "/tmp/project", &modal.SandboxFilesystemRemoveParams{Recursive: true})
```

{/snippet} </CodeTabs>

These APIs may be used to read files of up to 5GB and write files of any size.

However, if you have a large dataset that you want to use repeatedly from many sandboxes,
consider [using Volumes](#using-volumes).

<Callout variant="info">

Sandbox filesystem access was previously exposed through methods on the `Sandbox` and a `FileIO` object. This API is now deprecated; consult our [migration guide](/docs/guide/migrate-sandbox-filesystem) to update any code still using the legacy API.

</Callout>

## Using Volumes

It's possible to use Modal [Volume](/docs/sdk/py/latest/Volume)s or
[CloudBucketMount](/docs/guide/cloud-bucket-mounts)s with Sandboxes.

Volumes and CloudBucketMounts allow you to upload data once and access that
data efficiently from many sandboxes.

To access a Volume from a Sandbox, you can use the `volumes` parameter of `Sandbox.create`:

<CodeTabs>
  {#snippet python()}

```python notest
# Find or create a Volume with the name "my-volume".
vol = modal.Volume.from_name("my-volume", create_if_missing=True)
sb = modal.Sandbox.create(
    volumes={"/cache": vol},
    app=my_app,
)
# Read a file in the Volume.
p = sb.exec("bash", "-c", "cat /cache/some-file.txt")
print(p.stdout.read())
p.wait()

# Write a file to the Volume.
p = sb.exec("bash", "-c", "echo foo > /cache/a.txt")
p.wait()
sb.terminate(wait=True)

# Access the Volume file from outside the Sandbox.
for data in vol.read_file("a.txt"):
    print(data)
```

{/snippet}

{#snippet javascript()}

```javascript notest
const vol = await modal.volumes.fromName("my-volume", {
  createIfMissing: true,
});
const sb = await modal.sandboxes.create(app, image, {
  volumes: { "/cache": vol },
});

// Read a file in the Volume.
let p = await sb.exec(["bash", "-c", "cat /cache/some-file.txt"], {
  stdout: "pipe",
});
console.log(await p.stdout.readText());
await p.wait();

// Write a file to the Volume.
p = await sb.exec(["bash", "-c", "echo foo > /cache/a.txt"]);
await p.wait();
await sb.terminate({ wait: true });
```

{/snippet}

{#snippet go()}

```go notest
vol, _ := mc.Volumes.FromName(ctx, "my-volume", &modal.VolumeFromNameParams{
	CreateIfMissing: true,
})
sb, _ := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Volumes: map[string]*modal.Volume{"/cache": vol},
})

// Read a file in the Volume.
p, _ := sb.Exec(ctx, []string{"bash", "-c", "cat /cache/some-file.txt"}, &modal.SandboxExecParams{
	Stdout: modal.Pipe,
})
stdout, _ := io.ReadAll(p.Stdout)
fmt.Print(string(stdout))
p.Wait(ctx, nil)

// Write a file to the Volume.
p, _ = sb.Exec(ctx, []string{"bash", "-c", "echo foo > /cache/a.txt"}, nil)
p.Wait(ctx, nil)
sb.Terminate(ctx, nil)
```

{/snippet} </CodeTabs>

File syncing behavior differs between Volumes and CloudBucketMounts. For
Volumes, changes are persisted by [background commits](/docs/guide/volumes#background-commits)
that run every few seconds while the Sandbox executes, with a final commit when
the Sandbox terminates. With Volumes v2, you can also commit explicitly at any point (see
[Committing Volume changes with `sync`](#committing-volume-changes-with-sync-v2-only)
below). For CloudBucketMounts, files are synced automatically.

You need to explicitly reload a Volume to see changes made since it was first mounted, by invoking the [.reload\_volumes()](/docs/sdk/py/latest/Sandbox#reload_volumes) method on the sandbox object.

### Mounting a subdirectory

You can mount a subdirectory of a Volume instead of the entire Volume using
[`with_mount_options`](/docs/guide/volumes#mount-options). This is especially
useful when many Sandboxes share a single Volume but each Sandbox should only
access its own data:

<CodeTabs>
  {#snippet python()}

```python notest
sb_app = modal.App.lookup("my-app", create_if_missing=True)

vol = modal.Volume.from_name("shared-volume", create_if_missing=True)

# Each Sandbox only sees its own subdirectory of the Volume.
sb = modal.Sandbox.create(
    volumes={"/data": vol.with_mount_options(sub_path="/users/user_123")},
    app=sb_app,
)
# /data inside the Sandbox maps to /users/user_123 in the Volume.
# The Sandbox cannot see or modify files belonging to other users.
p = sb.exec("bash", "-c", "echo hello > /data/output.txt")
p.wait()
sb.terminate(wait=True)
```

{/snippet}

{#snippet javascript()}

```javascript notest
const vol = await modal.volumes.fromName("shared-volume", {
  createIfMissing: true,
});

// Each Sandbox only sees its own subdirectory of the Volume.
const sb = await modal.sandboxes.create(app, image, {
  volumes: { "/data": vol.withMountOptions({ subPath: "/users/user_123" }) },
});
// /data inside the Sandbox maps to /users/user_123 in the Volume.
// The Sandbox cannot see or modify files belonging to other users.
const p = await sb.exec(["bash", "-c", "echo hello > /data/output.txt"]);
await p.wait();
await sb.terminate({ wait: true });
```

{/snippet}

{#snippet go()}

```go notest
vol, _ := mc.Volumes.FromName(ctx, "shared-volume", &modal.VolumeFromNameParams{
	CreateIfMissing: true,
})

// Each Sandbox only sees its own subdirectory of the Volume.
subPath := "/users/user_123"
sb, _ := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Volumes: map[string]*modal.Volume{
		"/data": vol.WithMountOptions(&modal.VolumeMountOptionsParams{SubPath: &subPath}),
	},
})
defer sb.Terminate(ctx, nil)

// /data inside the Sandbox maps to /users/user_123 in the Volume.
// The Sandbox cannot see or modify files belonging to other users.
p, _ := sb.Exec(ctx, []string{"bash", "-c", "echo hello > /data/output.txt"}, nil)
p.Wait(ctx, nil)
```

{/snippet} </CodeTabs>

For more details on Volume mount options, see the
[Volumes guide](/docs/guide/volumes#mount-options).

### Committing Volume changes with `sync` (v2 only)

For [Volumes v2](/docs/guide/volumes#volumes-v2-overview), you can explicitly
commit changes at any point during Sandbox execution by running the `sync`
command on the mountpoint. This persists all data and metadata changes to the
Volume's storage without waiting for the Sandbox to terminate:

<CodeTabs>
  {#snippet python()}

```python notest
sb = modal.Sandbox.create(
    volumes={"/data": modal.Volume.from_name("my-v2-volume")},
    app=my_app,
)

# Write files to the volume
sb.exec("bash", "-c", "echo 'hello' > /data/output.txt").wait()

# Commit changes immediately
p = sb.exec("sync", "/data")
p.wait()
if p.returncode != 0:
    raise Exception(f"sync failed with exit code {p.returncode}")

# Changes are now persisted and visible to other containers
sb.terminate()
```

{/snippet}

{#snippet javascript()}

```javascript notest
const vol = await modal.volumes.fromName("my-v2-volume");
const sb = await modal.sandboxes.create(app, image, {
  volumes: { "/data": vol },
});

// Write files to the Volume.
let p = await sb.exec(["bash", "-c", "echo 'hello' > /data/output.txt"]);
await p.wait();

// Commit changes immediately.
p = await sb.exec(["sync", "/data"]);
const code = await p.wait();
if (code !== 0) {
  throw new Error(`sync failed with exit code ${code}`);
}

// Changes are now persisted and visible to other containers.
await sb.terminate();
```

{/snippet}

{#snippet go()}

```go notest
vol, _ := mc.Volumes.FromName(ctx, "my-v2-volume", nil)
sb, _ := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Volumes: map[string]*modal.Volume{"/data": vol},
})

// Write files to the Volume.
p, _ := sb.Exec(ctx, []string{"bash", "-c", "echo 'hello' > /data/output.txt"}, nil)
p.Wait(ctx, nil)

// Commit changes immediately.
p, _ = sb.Exec(ctx, []string{"sync", "/data"}, nil)
returnCode, _ := p.Wait(ctx, nil)
if returnCode != 0 {
	panic(fmt.Sprintf("sync failed with exit code %d", returnCode))
}

// Changes are now persisted and visible to other containers.
sb.Terminate(ctx, nil)
```

{/snippet} </CodeTabs>

This is particularly useful for long-running Sandboxes where you want to
persist intermediate results, or when you need changes to be visible to other
containers before the Sandbox terminates.

## Adding files to an Image

In some cases, you may want to [add a file to an Image itself](/docs/guide/images#add-local-files-with-add_local_dir-and-add_local_file).
This is useful if the file will be used by many Sandboxes, or if you
want to access that file from the Sandbox's entrypoint command.

This can be done using the
[`add_local_file`](/docs/sdk/py/latest/Image#add_local_file) and
[`add_local_dir`](/docs/sdk/py/latest/Image#add_local_dir) methods on the
[`Image`](/docs/sdk/py/latest/Image) class:

```python notest
# The Image is built and published ahead of time, so Sandbox creation never
# waits on a build. `copy=True` bakes the files into the Image; without it they
# are attached at container start and are not part of the published Image.
#
#     image = (
#         modal.Image.debian_slim()
#         .add_local_dir(
#             local_path="/home/user/my_dir",
#             remote_path="/app",
#             copy=True,
#         )
#     )
#     image.build(my_app).publish("sandbox-with-local-files")

sb = modal.Sandbox.create(
    app=my_app,
    # prefer named Images in Sandboxes to ensure they are never built during Sandbox launch
    image=modal.Image.from_name("sandbox-with-local-files"),
)
p = sb.exec("ls", "/app")
print(p.stdout.read())
p.wait()
```
