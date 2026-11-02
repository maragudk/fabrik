# Running commands in Sandboxes

Once you have created a Sandbox, you can run commands inside it with its `exec`
method.

<CodeTabs>
  {#snippet python()}

```python notest
sb = modal.Sandbox.create(app=my_app)

process = sb.exec("echo", "hello", timeout=3)  # timeout in seconds
print(process.stdout.read())

process = sb.exec("python", "-c", "print(1 + 1)", timeout=3)
print(process.stdout.read())

process = sb.exec(
    "bash",
    "-c",
    "for i in $(seq 1 10); do echo foo $i; sleep 0.1; done",
    timeout=5,
)
for line in process.stdout:
    print(line, end="")

sb.terminate()
```

{/snippet}

{#snippet javascript()}

```javascript notest
import { ModalClient } from "modal";

const modal = new ModalClient();
const app = await modal.apps.fromName("sandbox-exec", {
  createIfMissing: true,
});
const image = modal.images.fromRegistry("python:3.13-slim");
const sb = await modal.sandboxes.create(app, image);

let p = await sb.exec(["echo", "hello"], {
  timeoutMs: 3000,
  stdout: "pipe",
});
console.log(await p.stdout.readText());

p = await sb.exec(["python", "-c", "print(1 + 1)"], {
  timeoutMs: 3000,
  stdout: "pipe",
});
console.log(await p.stdout.readText());

p = await sb.exec(
  ["bash", "-c", "for i in $(seq 1 10); do echo foo $i; sleep 0.1; done"],
  { timeoutMs: 5000, stdout: "pipe" },
);
for await (const chunk of p.stdout) {
  process.stdout.write(chunk);
}
await sb.terminate();
```

{/snippet}

{#snippet go()}

```go notest
package main

import (
	"context"
	"fmt"
	"io"
	"os"
	"time"

	modal "github.com/modal-labs/modal-client/go"
)

func main() {
	ctx := context.Background()
	mc, _ := modal.NewClient()

	app, _ := mc.Apps.FromName(ctx, "sandbox-exec", &modal.AppFromNameParams{
		CreateIfMissing: true,
	})
	image := mc.Images.FromRegistry("python:3.13-slim", nil)
	sb, _ := mc.Sandboxes.Create(ctx, app, image, nil)

	process, _ := sb.Exec(ctx, []string{"echo", "hello"}, &modal.SandboxExecParams{
		Timeout: 3 * time.Second,
		Stdout:  modal.Pipe,
	})
	stdout, _ := io.ReadAll(process.Stdout)
	fmt.Print(string(stdout))

	process, _ = sb.Exec(ctx, []string{"python", "-c", "print(1 + 1)"}, &modal.SandboxExecParams{
		Timeout: 3 * time.Second,
		Stdout:  modal.Pipe,
	})
	stdout, _ = io.ReadAll(process.Stdout)
	fmt.Print(string(stdout))

	process, _ = sb.Exec(ctx, []string{
		"bash", "-c", "for i in $(seq 1 10); do echo foo $i; sleep 0.1; done",
	}, &modal.SandboxExecParams{
		Timeout: 5 * time.Second,
		Stdout:  modal.Pipe,
	})
	io.Copy(os.Stdout, process.Stdout)
	sb.Terminate(ctx, nil)
}
```

{/snippet} </CodeTabs>

`exec` returns a process object with the command's standard input, output, and
error streams. The timeout caps how long the command can run.

## Input

To send data to a command, write to its standard input, then close the stream
to signal EOF:

<CodeTabs>
  {#snippet python()}

```python notest
import asyncio

sb = modal.Sandbox.create(app=my_app)

p = sb.exec("bash", "-c", "while read line; do echo $line; done")
p.stdin.write(b"foo bar\n")
p.stdin.write_eof()
p.stdin.drain()
p.wait()
sb.terminate()

async def run_async():
    sb = await modal.Sandbox.create.aio(app=my_app)
    p = await sb.exec.aio("bash", "-c", "while read line; do echo $line; done")
    p.stdin.write(b"foo bar\n")
    p.stdin.write_eof()
    await p.stdin.drain.aio()
    await p.wait.aio()
    await sb.terminate.aio()

asyncio.run(run_async())
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image);

const p = await sb.exec(["bash", "-c", "while read line; do echo $line; done"]);
await p.stdin.writeText("foo bar\n");
await p.stdin.close();
await p.wait();
await sb.terminate();
```

{/snippet}

{#snippet go()}

```go notest
sb, _ := mc.Sandboxes.Create(ctx, app, image, nil)

p, _ := sb.Exec(ctx, []string{
	"bash", "-c", "while read line; do echo $line; done",
}, nil)
p.Stdin.Write([]byte("foo bar\n"))
p.Stdin.Close()
p.Wait(ctx, nil)
sb.Terminate(ctx, nil)
```

{/snippet} </CodeTabs>

## Output

Read a command's output from its standard output and error streams. Reads from
these streams also respect the exec timeout.

<CodeTabs>
  {#snippet python()}

```python notest
sb = modal.Sandbox.create(app=my_app)
p = sb.exec("echo", "hello")
print(p.stdout.read())
sb.terminate()
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image);

const p = await sb.exec(["echo", "hello"], { stdout: "pipe" });
console.log(await p.stdout.readText());
await sb.terminate();
```

{/snippet}

{#snippet go()}

```go notest
sb, _ := mc.Sandboxes.Create(ctx, app, image, nil)

p, _ := sb.Exec(ctx, []string{"echo", "hello"}, &modal.SandboxExecParams{
	Stdout: modal.Pipe,
})
stdout, _ := io.ReadAll(p.Stdout)
fmt.Print(string(stdout))
sb.Terminate(ctx, nil)
```

{/snippet} </CodeTabs>

To stream output, read it as the command produces it:

<CodeTabs>
  {#snippet python()}

```python notest
import asyncio

sb = modal.Sandbox.create(app=my_app)

p = sb.exec("bash", "-c", "for i in $(seq 1 10); do echo foo $i; sleep 0.1; done")

for line in p.stdout:
    # Lines preserve the trailing newline character, so use end="" to avoid double newlines.
    print(line, end="")
p.wait()
sb.terminate()

async def run_async():
    sb = await modal.Sandbox.create.aio(app=my_app)
    p = await sb.exec.aio("bash", "-c", "for i in $(seq 1 10); do echo foo $i; sleep 0.1; done")
    async for line in p.stdout:
        # Avoid double newlines by using end="".
        print(line, end="")
    await p.wait.aio()
    await sb.terminate.aio()

asyncio.run(run_async())
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image);

const p = await sb.exec([
  "bash",
  "-c",
  "for i in $(seq 1 10); do echo foo $i; sleep 0.1; done",
]);
for await (const chunk of p.stdout) {
  process.stdout.write(chunk);
}
await p.wait();
await sb.terminate();
```

{/snippet}

{#snippet go()}

```go notest
sb, _ := mc.Sandboxes.Create(ctx, app, image, nil)

p, _ := sb.Exec(ctx, []string{
	"bash", "-c", "for i in $(seq 1 10); do echo foo $i; sleep 0.1; done",
}, nil)
io.Copy(os.Stdout, p.Stdout)
p.Wait(ctx, nil)
sb.Terminate(ctx, nil)
```

{/snippet} </CodeTabs>

### Stream types

By default, each stream is piped: Modal keeps its output so your client can read
it. Use the `stdout` and `stderr` options to discard a stream's output instead.

<CodeTabs>
  {#snippet python()}

```python notest
from modal.stream_type import StreamType

sb = modal.Sandbox.create(app=my_app)

# Default behavior: buffered in memory.
p = sb.exec(
    "bash",
    "-c",
    "echo foo; echo bar >&2",
    stdout=StreamType.PIPE,
    stderr=StreamType.PIPE,
)
print(p.stdout.read())
print(p.stderr.read())

# Print the stream to STDOUT as it comes in.
p = sb.exec(
    "bash",
    "-c",
    "echo foo; echo bar >&2",
    stdout=StreamType.STDOUT,
    stderr=StreamType.STDOUT,
)
p.wait()

# Discard all output.
p = sb.exec(
    "bash",
    "-c",
    "echo foo; echo bar >&2",
    stdout=StreamType.DEVNULL,
    stderr=StreamType.DEVNULL,
)
p.wait()

sb.terminate()
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image);

// Pipe output so it can be read from the process streams.
let p = await sb.exec(["bash", "-c", "echo foo; echo bar >&2"], {
  stdout: "pipe",
  stderr: "pipe",
});
console.log(await p.stdout.readText());
console.log(await p.stderr.readText());

// Forward both streams to the local stdout as they arrive.
p = await sb.exec(["bash", "-c", "echo foo; echo bar >&2"], {
  stdout: "pipe",
  stderr: "pipe",
});
for await (const chunk of p.stdout) process.stdout.write(chunk);
for await (const chunk of p.stderr) process.stdout.write(chunk);
await p.wait();

// Discard all output.
p = await sb.exec(["bash", "-c", "echo foo; echo bar >&2"], {
  stdout: "ignore",
  stderr: "ignore",
});
await p.wait();
await sb.terminate();
```

{/snippet}

{#snippet go()}

```go notest
sb, _ := mc.Sandboxes.Create(ctx, app, image, nil)

// Pipe output so it can be read from the process streams.
p, _ := sb.Exec(ctx, []string{"bash", "-c", "echo foo; echo bar >&2"}, &modal.SandboxExecParams{
	Stdout: modal.Pipe,
	Stderr: modal.Pipe,
})
stdout, _ := io.ReadAll(p.Stdout)
stderr, _ := io.ReadAll(p.Stderr)
fmt.Printf("%s%s", stdout, stderr)

// Forward both streams to the local stdout as they arrive.
p, _ = sb.Exec(ctx, []string{"bash", "-c", "echo foo; echo bar >&2"}, &modal.SandboxExecParams{
	Stdout: modal.Pipe,
	Stderr: modal.Pipe,
})
io.Copy(os.Stdout, p.Stdout)
io.Copy(os.Stdout, p.Stderr)
p.Wait(ctx, nil)

// Discard all output.
p, _ = sb.Exec(ctx, []string{"bash", "-c", "echo foo; echo bar >&2"}, &modal.SandboxExecParams{
	Stdout: modal.Ignore,
	Stderr: modal.Ignore,
})
p.Wait(ctx, nil)
sb.Terminate(ctx, nil)
```

{/snippet} </CodeTabs>

An exec's stdout and stderr are streamed to your client only when you read from
them. Reading a stream to the end returns all of its output; if the process is
still running, the read blocks until the process finishes. After an exec
completes, you can read its output for up to 10 minutes. Modal then discards the
output, so later reads will fail.
