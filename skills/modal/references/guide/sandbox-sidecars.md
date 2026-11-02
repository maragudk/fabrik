# Sandbox Sidecars

<Callout variant="beta">

There are currently several [known limitations](#limitations).

</Callout>

## Introduction

Sandbox Sidecars are isolated containers that run alongside your main Sandbox
container on the same host. They provide a low-latency trust boundary, letting you
split code with different levels of trust across containers. For example, you can
keep credentials, proxies, or monitoring in a Sidecar that the main container
cannot directly access.

Because a Sandbox and its Sidecars run on the same host, communication between
them stays local instead of crossing a remote service boundary. This makes
Sidecars ideal for:

* Separating an agent harness from its execution environment, by running the
  agent in one container and its tool calls in another. See the [agent example](/docs/examples/sidecar_agent)
  for the general shape.
* Credentials injection, by running a proxy in a separate, trusted container
  from the primary application, and letting that proxy inject credentials
  or other secrets before passing on network calls to external services. The
  [credential proxy example](/docs/examples/sidecar_secrets_injection) uses
  a Modal [Secret](/docs/guide/secrets) that is injected only in the sidecar.
* Monitoring and filtering outbound traffic, by [routing the Sandbox's HTTPS
  traffic through a proxy Sidecar](#routing-https-traffic-through-a-sidecar)
  with your own rules. The [traffic routing example](/docs/examples/sidecar_traffic_routing)
  shows a mitmproxy-based request filter.
* Splitting out complex multi-service applications over separate containers,
  such as databases, caches or worker processes, similar to Docker Compose. The
  [Redis example](/docs/examples/sidecar_redis) shows the pattern.

We're still discovering all the ways that Sandbox Sidecars can be used - if you
come up with another use case, please let us know! For more background on why
we built Sidecars, see the [Sidecars launch blog post](https://modal.com/blog/introducing-sandbox-sidecars-trust-boundary).

Sidecars are managed through the sidecars interface on a Sandbox
(`_experimental_sidecars` in Python, `experimentalSidecars` in JS/Go),
which provides methods to create, list, get, and terminate Sidecar containers.

Each Sidecar container:

* Runs its own image independently from the main Sandbox container.
* Is isolated from the main Sandbox container and other Sidecar containers with
  the same isolation boundary as separate Sandboxes: gVisor or a VM, depending on
  the Sandbox's [runtime](/docs/guide/sandboxes#runtimes).
* Can communicate over an internal bridge network with the main Sandbox container
  and other Sidecar containers. In our benchmarks, communication between a Sandbox
  and its Sidecars is at least 3x faster than between separate Sandboxes in the
  same region.
* Is created through the Modal SDK, not from inside the Sandbox, so code running
  in the main Sandbox container can't create or modify it.
* Can be created, terminated, and replaced dynamically during the Sandbox's lifetime.
  Terminating the Sandbox stops all of its Sidecars.
* Has its own [outbound network policy](#outbound-access-control), independent of the main Sandbox container.
* Shares the CPU and memory of the Sandbox, which makes Sidecars more cost-efficient
  than running the same processes across multiple Sandboxes. See
  [Resource configuration](#resource-configuration).
* Supports executing commands just like the main Sandbox container.

## Usage

### Creating a Sidecar container

The main Sandbox container is resolvable as `main`, and each Sidecar container
is resolvable by the `name` you give it at creation time. Names are resolved using `/etc/hosts` which gets
updated when a sidecar is created or terminated.

<CodeTabs>
{#snippet python()}

```python notest
import modal

app = modal.App.lookup("sidecar-example", create_if_missing=True)
# prefer named Images in Sandboxes to ensure they are never built during Sandbox launch
image = modal.Image.from_name("sandbox-runtime")

sb = modal.Sandbox.create("sleep", "600", app=app, image=image, timeout=300)

sidecar = sb._experimental_sidecars.create(
    "python",
    "-m",
    "http.server",
    "8080",
    name="web",
    image=image,
)

# Give the server a moment to start, then call it from the main sandbox.
p = sb.exec(
    "python",
    "-c",
    "import time, urllib.request; time.sleep(1); print(urllib.request.urlopen('http://web:8080').status)",
)
p.wait()
print(p.stdout.read())  # "200"

sb.terminate()
```

{/snippet}

{#snippet javascript()}

```javascript notest
import { ModalClient } from "modal";

const modal = new ModalClient();
const app = await modal.apps.fromName("sidecar-example", {
  createIfMissing: true,
});
// prefer named Images in Sandboxes to ensure they are never built during Sandbox launch
const image = await modal.images.fromName("sandbox-runtime");

const sb = await modal.sandboxes.create(app, image, {
  command: ["sleep", "600"],
  timeoutMs: 300 * 1000,
});

const sidecar = await sb.experimentalSidecars.create("web", image, {
  command: ["python", "-m", "http.server", "8080"],
});

// Give the server a moment to start, then call it from the main sandbox.
const p = await sb.exec([
  "python",
  "-c",
  "import time, urllib.request; time.sleep(1); print(urllib.request.urlopen('http://web:8080').status)",
]);
await p.wait();
console.log(await p.stdout.readText()); // "200"

await sb.terminate();
```

{/snippet}

{#snippet go()}

```go
package main

import (
	"context"
	"fmt"
	"io"
	"time"

	modal "github.com/modal-labs/modal-client/go"
)

func main() {
	ctx := context.Background()
	mc, _ := modal.NewClient()

	app, _ := mc.Apps.FromName(ctx, "sidecar-example", &modal.AppFromNameParams{
		CreateIfMissing: true,
	})
	// prefer named Images in Sandboxes to ensure they are never built during Sandbox launch
	image, _ := mc.Images.FromName(ctx, "sandbox-runtime", nil)

	sb, _ := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
		Command: []string{"sleep", "600"},
		Timeout: 5 * time.Minute,
	})
	defer sb.Terminate(ctx, nil)

	sidecar, _ := sb.ExperimentalSidecars.Create(ctx, "web", image, &modal.SidecarCreateParams{
		Command: []string{"python", "-m", "http.server", "8080"},
	})
	_ = sidecar

	// Give the server a moment to start, then call it from the main sandbox.
	p, _ := sb.Exec(ctx, []string{
		"python", "-c",
		"import time, urllib.request; time.sleep(1); print(urllib.request.urlopen('http://web:8080').status)",
	}, nil)
	stdout, _ := io.ReadAll(p.Stdout)
	fmt.Println(string(stdout)) // "200"
}
```

{/snippet} </CodeTabs>

### Listing and retrieving sidecars

You can list all running Sidecar containers or retrieve a specific one by name:

<CodeTabs>
{#snippet python()}

```python notest
containers = sb._experimental_sidecars.list()
for container in containers:
    print(f"{container.name}: {container.object_id}")

sidecar = sb._experimental_sidecars.get(name="web")
```

{/snippet}

{#snippet javascript()}

```javascript notest
const containers = await sb.experimentalSidecars.list();
for (const container of containers) {
  console.log(`${container.containerName}: ${container.containerId}`);
}

const sidecar = await sb.experimentalSidecars.get("web");
```

{/snippet}

{#snippet go()}

```go notest
containers, _ := sb.ExperimentalSidecars.List(ctx, nil)
for _, container := range containers {
	fmt.Printf("%s: %s\n", container.ContainerName, container.ContainerID)
}

sidecar, _ := sb.ExperimentalSidecars.Get(ctx, "web", nil)
_ = sidecar
```

{/snippet} </CodeTabs>

### OIDC tokens

Like Sandboxes, Sidecars do not receive an [OIDC](/docs/guide/oidc-integration)
token by default. To opt in, pass `include_oidc_identity_token=True` when creating
a Sidecar. The token is then available inside the Sidecar via the
`MODAL_IDENTITY_TOKEN` environment variable. The Sidecar’s identity token is issued
for its container, so its `container_id` claim differs from the corresponding Sandbox’s.

### Filesystem snapshots

You can snapshot a running Sidecar's filesystem into a reusable Image. The
resulting Image can be used anywhere an existing Image is accepted; the example
below uses it to start another Sidecar. The snapshot is scoped to that Sidecar;
it does not include the main Sandbox filesystem or other Sidecars.

<CodeTabs>
{#snippet python()}

```python notest
sidecar.filesystem.write_text("ready", "/tmp/state")
snapshot = sidecar.snapshot_filesystem()

restored = sb._experimental_sidecars.create(
    "sleep", "600", name="restored", image=snapshot
)
assert restored.filesystem.read_text("/tmp/state") == "ready"
```

{/snippet}

{#snippet javascript()}

```javascript notest
await sidecar.filesystem.writeText("ready", "/tmp/state");
const snapshot = await sidecar.snapshotFilesystem();

const restored = await sb.experimentalSidecars.create("restored", snapshot, {
  command: ["sleep", "600"],
});
console.assert((await restored.filesystem.readText("/tmp/state")) === "ready");
```

{/snippet}

{#snippet go()}

```go notest
_ = sidecar.Filesystem.WriteText(ctx, "ready", "/tmp/state", nil)
snapshot, _ := sidecar.SnapshotFilesystem(ctx, nil)

restored, _ := sb.ExperimentalSidecars.Create(ctx, "restored", snapshot, &modal.SidecarCreateParams{
	Command: []string{"sleep", "600"},
})
state, _ := restored.Filesystem.ReadText(ctx, "/tmp/state", nil)
fmt.Println(state) // "ready"
```

{/snippet} </CodeTabs>

### Directory mounts and snapshots

You can mount an Image at an absolute path in a running Sidecar and unmount it
later. You can also [snapshot a Sidecar directory](/docs/guide/sandbox-snapshots#directory-snapshots) into a new Image. The resulting
Image can be used anywhere an existing Image is accepted, including as a mount
or as the filesystem for a new container.

The example below uses a mounted `/workspace` as session state, snapshots it,
terminates the original Sidecar, and mounts the snapshot in a replacement
Sidecar:

<CodeTabs>
{#snippet python()}

```python notest
sidecar.mount_image("/workspace", modal.Image.from_scratch())
sidecar.filesystem.write_text("ready", "/workspace/state")

workspace = sidecar.snapshot_directory("/workspace")
sidecar.terminate(wait=True)

replacement = sb._experimental_sidecars.create(
    "sleep", "600", name="replacement", image=image
)
replacement.mount_image("/workspace", workspace)
assert replacement.filesystem.read_text("/workspace/state") == "ready"
replacement.unmount_image("/workspace")
```

{/snippet}

{#snippet javascript()}

```javascript notest
await sidecar.mountImage("/workspace");
await sidecar.filesystem.writeText("ready", "/workspace/state");

const workspace = await sidecar.snapshotDirectory("/workspace");
await sidecar.terminate({ wait: true });

const replacement = await sb.experimentalSidecars.create("replacement", image, {
  command: ["sleep", "600"],
});
await replacement.mountImage("/workspace", workspace);
console.assert(
  (await replacement.filesystem.readText("/workspace/state")) === "ready",
);
await replacement.unmountImage("/workspace");
```

{/snippet}

{#snippet go()}

```go notest
_ = sidecar.MountImage(ctx, "/workspace", nil, nil)
_ = sidecar.Filesystem.WriteText(ctx, "ready", "/workspace/state", nil)

workspace, _ := sidecar.SnapshotDirectory(ctx, "/workspace", nil)
_, _ = sidecar.Terminate(ctx, &modal.SidecarTerminateParams{Wait: true})

replacement, _ := sb.ExperimentalSidecars.Create(ctx, "replacement", image, &modal.SidecarCreateParams{
	Command: []string{"sleep", "600"},
})
_ = replacement.MountImage(ctx, "/workspace", workspace, nil)
state, _ := replacement.Filesystem.ReadText(ctx, "/workspace/state", nil)
fmt.Println(state) // "ready"
_ = replacement.UnmountImage(ctx, "/workspace", nil)
```

{/snippet} </CodeTabs>

### Volumes

A Sidecar can mount [Volumes](/docs/guide/volumes), configured the same way as
on a Sandbox. Each container gets its own mount. You can mount the same Volume
in the main Sandbox and in other Sidecars to share data between them.

### Cloud Bucket Mounts

A Sidecar can mount [Cloud Bucket Mounts](/docs/guide/cloud-bucket-mounts),
configured the same way as on a Sandbox. Each container gets its own mount:
a bucket mounted in a Sidecar is not visible in the main Sandbox container or
in other Sidecars, so mount it in every container that needs it. Cloud Bucket
Mounts are not supported in Sidecars of GPU Sandboxes.

<CodeTabs>
{#snippet python()}

```python notest
bucket = modal.CloudBucketMount(
    "my-bucket",
    secret=modal.Secret.from_name("my-aws-secret"),
    read_only=True,
)

reader = sb._experimental_sidecars.create(
    "sleep", "600", name="reader", image=image, volumes={"/mnt/bucket": bucket}
)
p = reader.exec("ls", "/mnt/bucket")
p.wait()
print(p.stdout.read())
```

{/snippet}

{#snippet javascript()}

```javascript notest
const secret = await modal.secrets.fromName("my-aws-secret");

const reader = await sb.experimentalSidecars.create("reader", image, {
  command: ["sleep", "600"],
  cloudBucketMounts: {
    "/mnt/bucket": modal.cloudBucketMounts.create("my-bucket", {
      secret,
      readOnly: true,
    }),
  },
});
const p = await reader.exec(["ls", "/mnt/bucket"]);
await p.wait();
console.log(await p.stdout.readText());
```

{/snippet}

{#snippet go()}

```go notest
secret, _ := mc.Secrets.FromName(ctx, "my-aws-secret", nil)
bucket, _ := mc.CloudBucketMounts.New("my-bucket", &modal.CloudBucketMountParams{
	Secret:   secret,
	ReadOnly: true,
})

reader, _ := sb.ExperimentalSidecars.Create(ctx, "reader", image, &modal.SidecarCreateParams{
	Command:           []string{"sleep", "600"},
	CloudBucketMounts: map[string]*modal.CloudBucketMount{"/mnt/bucket": bucket},
})
p, _ := reader.Exec(ctx, []string{"ls", "/mnt/bucket"}, nil)
stdout, _ := io.ReadAll(p.Stdout)
fmt.Println(string(stdout))
```

{/snippet} </CodeTabs>

With [OIDC authentication](/docs/guide/cloud-bucket-mounts#using-oidc-identity-tokens),
the identity token is issued for the Sidecar container, so its `container_id`
claim differs from the main container's. An IAM trust policy that matches on
the full subject must allow the Sidecar's container ID as well.

## Networking

### Communication between containers

The main Sandbox container is reachable by the hostname `main`, and each
Sidecar is reachable by the `name` it was created with. These hostnames are
listed in `/etc/hosts`.

Traffic between containers in the same Sandbox is not subject to any
container's outbound allowlists, whether CIDR or domain. For example, a main
container with an `outbound_domain_allowlist` can connect to a Sidecar by name,
and a Sidecar with an empty `outbound_cidr_allowlist` can still reach `main`.
This applies only to containers in the same Sandbox; other private IP addresses
remain blocked.

### Outbound access control

Each Sidecar has its own outbound network policy, independent of the main
container's and open by default. A Sidecar does not inherit the Sandbox's
`outbound_cidr_allowlist` or `outbound_domain_allowlist`, and restricting one
Sidecar does not affect the main container or other Sidecars.

Set a Sidecar's outbound allowlists when you create it. These options behave
like the Sandbox options of the same name:

* `outbound_cidr_allowlist` only allows traffic to the listed IP ranges, using
  any protocol.
* `outbound_domain_allowlist` only allows TLS traffic on port 443 to the listed
  domains, matched on
  [SNI](/docs/guide/sandbox-networking#how-domain-filtering-works). Wildcard
  prefixes such as `*.example.com` are supported.
* When both allowlists are set, traffic that matches either one is allowed.

<CodeTabs>
{#snippet python()}

```python notest
sidecar = sb._experimental_sidecars.create(
    "sleep",
    "600",
    name="restricted",
    image=image,
    outbound_cidr_allowlist=["52.0.0.0/8"],
    outbound_domain_allowlist=["api.openai.com", "*.github.com"],
)
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sidecar = await sb.experimentalSidecars.create("restricted", image, {
  command: ["sleep", "600"],
  outboundCidrAllowlist: ["52.0.0.0/8"],
  outboundDomainAllowlist: ["api.openai.com", "*.github.com"],
});
```

{/snippet}

{#snippet go()}

```go notest
sidecar, _ := sb.ExperimentalSidecars.Create(ctx, "restricted", image, &modal.SidecarCreateParams{
	Command:                 []string{"sleep", "600"},
	OutboundCIDRAllowlist:   &modal.Allowlist{Entries: []string{"52.0.0.0/8"}},
	OutboundDomainAllowlist: &modal.Allowlist{Entries: []string{"api.openai.com", "*.github.com"}},
})
_ = sidecar
```

{/snippet} </CodeTabs>

Sidecars do not support `block_network`, because a fully network-blocked Sidecar
couldn't reach the main container. To block all external egress while keeping
connectivity to other containers in the Sandbox, pass an empty CIDR allowlist:

* Python: `outbound_cidr_allowlist=[]`
* JavaScript: `outboundCidrAllowlist: []`
* Go: `OutboundCIDRAllowlist: &modal.Allowlist{}`

<Callout variant="warning">

DNS lookups through Modal's resolver still work when a Sidecar has an allowlist,
including an empty CIDR allowlist. Public resolvers such as `8.8.8.8` are blocked
unless you include them in the allowlist.

</Callout>

A Sidecar's outbound network policy is fixed when the Sidecar is created.
Updating the Sandbox's network policy at runtime
(`_experimental_set_outbound_network_policy` in Python, `updateNetworkPolicy` in
JavaScript, `UpdateNetworkPolicy` in Go) only changes the main container's
policy and never affects Sidecars. To change a Sidecar's policy, terminate it
and create a replacement.

| Option                                                  | Sandbox (main container) | Sidecar                                               |
| ------------------------------------------------------- | ------------------------ | ----------------------------------------------------- |
| `block_network`                                         | Supported                | Not supported. Use an empty `outbound_cidr_allowlist` |
| `outbound_cidr_allowlist`                               | Supported                | Supported, set per Sidecar                            |
| `outbound_domain_allowlist` *(Beta)*                    | Supported                | Supported, set per Sidecar                            |
| Modal Proxy (`proxy`)                                   | Supported                | Supported, set per Sidecar (not on GPU Sandboxes)     |
| [Outbound Policy](/docs/guide/sandbox-secret-injection) | Supported                | Not supported                                         |
| Updating the policy at runtime                          | Supported (experimental) | Not supported; create a replacement Sidecar           |

### Modal Proxy

You can specify that traffic from a Sidecar should exit through a
[Proxy](/docs/guide/proxy-ips) by passing a `proxy` at Sidecar creation, just as
for a Sandbox. A Sidecar's Proxy is configured independently of the main
container's, so its static outbound IP can differ from the main container's.
Using a Proxy with a Sidecar is not supported for GPU
Sandboxes; the client raises an error.

### Routing HTTPS traffic through a Sidecar

Sidecars can be used to inspect the outgoing HTTPS traffic from the main Sandbox
container in a different context, for example to perform more advanced request
filtering, inspecting requests for logging, or injecting secrets that the main
Sandbox container should not have access to.

Normally, applications need to support explicit proxy configuration, such as
respecting the `HTTPS_PROXY` environment variable, to route traffic through a Sidecar.
To include HTTPS traffic (TCP on port 443) from **proxy-unaware** applications, you can
set the experimental `proxy_traffic_via_sidecar` option that routes **all** outbound
HTTPS traffic from the main Sandbox container through a Sidecar.

<CodeTabs>
{#snippet python()}

```python notest
sb = modal.Sandbox.create(
    "sleep",
    "600",
    app=app,
    image=image,
    experimental_options={"proxy_traffic_via_sidecar": "my-proxy-sidecar"},
)

# Until this Sidecar is running, HTTPS from the main container is refused.
sb._experimental_sidecars.create("python", "/proxy.py", name="my-proxy-sidecar", image=proxy_image)
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image, {
  command: ["sleep", "600"],
  experimentalOptions: { proxy_traffic_via_sidecar: "my-proxy-sidecar" },
});

// Until this Sidecar is running, HTTPS from the main container is refused.
await sb.experimentalSidecars.create("my-proxy-sidecar", proxyImage, {
  command: ["python", "/proxy.py"],
});
```

{/snippet}

{#snippet go()}

```go notest
sb, _ := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Command:             []string{"sleep", "600"},
	ExperimentalOptions: map[string]any{"proxy_traffic_via_sidecar": "my-proxy-sidecar"},
})
// Until this Sidecar is running, HTTPS from the main container is refused.
sb.ExperimentalSidecars.Create(ctx, "my-proxy-sidecar", proxyImage, &modal.SidecarCreateParams{
	Command: []string{"python", "/proxy.py"},
})
```

{/snippet} </CodeTabs>

The Sidecar receives a raw TLS stream and must read the destination hostname
from the `ClientHello`'s SNI. The original destination IP is not forwarded, so
mechanisms such as `SO_ORIGINAL_DST` do not work. To read or rewrite HTTP
requests, terminate TLS in the proxy using a certificate authority that the
Sandbox trusts. See the [Sidecar traffic routing
example](/docs/examples/sidecar_traffic_routing) for a complete mitmproxy-based
request filter.

Only TCP traffic to port 443 from the main container is relayed. Egress from the
proxy Sidecar itself, and from any other Sidecars, is not relayed and follows
each container's own [outbound access controls](#outbound-access-control).

The relay fails closed. Until a Sidecar with the configured name is running,
and after it exits, HTTPS connections from the main container are refused
instead of going out directly. A new Sidecar created with the same name takes
over the relay.

#### Interaction with egress controls

* An `outbound_cidr_allowlist` on the Sandbox governs every port other than
  443, but relayed traffic on port 443 passes regardless of what the allowlist
  contains.
* Relayed traffic is governed by the proxy Sidecar's own egress controls, which
  default to open. Unless you pass `outbound_cidr_allowlist` or
  `outbound_domain_allowlist` to the proxy Sidecar, relayed traffic can reach any
  destination the proxy Sidecar connects to.

`proxy_traffic_via_sidecar` cannot be combined with `block_network`,
`outbound_domain_allowlist`, a Modal Proxy (`proxy`), or an
[Outbound Policy](/docs/guide/sandbox-secret-injection) on the Sandbox. A
Sandbox `outbound_cidr_allowlist` is allowed.

For `proxy_traffic_via_sidecar`, the Sidecar name can't be empty or `main`, must
be at most 64 characters long, and may contain only letters, digits, dashes,
and underscores.

### Connect Tokens

<Callout variant="info">

Sidecars can connect directly to every port on the main container, including
the port that [Connect Tokens](/docs/guide/sandbox-networking#connecting-to-sandboxes-with-http-and-websockets)
route requests to. Requests a Sidecar sends to that port do not need a token,
and can set any `X-Verified-User-Data` header. If your server in the main
container trusts that header, avoid using Connect Tokens and Sidecars together
in the same Sandbox.

</Callout>

## Resource configuration

The main Sandbox container and the Sidecar containers share the resource allocation (CPU and memory) of the Sandbox,
and resources are configured only on the Sandbox. When planning your
resource allocation, make sure the Sandbox is configured with enough CPU
and memory for all containers combined.

For example, if you want to run a Sandbox with two Sidecars, and you expect the main
container to use 1 CPU core and 512 MiB of memory, Sidecar A to use 0.5 CPU and 256 MiB,
and Sidecar B to use 0.5 CPU and 256 MiB, you should set the Sandbox's resources to at
least 2 CPUs and 1024 MiB to accommodate all three containers.

There is a hard limit of **250** concurrent sidecar containers per sandbox,
regardless of the resource reservation.

On the gVisor runtime, bursting is still possible; see the [guide to Sandbox resources and
pricing](/docs/guide/sandbox-resources) for more details.

On the VM runtime, you need to reserve memory for any Sidecars when you launch the Sandbox.
The reserve is carved out of the main VM's memory: it boots with `memory - reserve` and, if the
Sandbox uses [memory bursting](/docs/guide/sandbox-resources), never grows past `limit - reserve`,
leaving the reserve for Sidecars. The request must leave the main VM at least 1024 MiB. With every
Sidecar launch, you either specify how much of the reserve to use for that Sidecar, or leave the
option empty to use the entire remaining reserve:

<CodeTabs>
{#snippet python()}

```python notest
sb = modal.Sandbox.create(
    "sleep",
    "600",
    app=app,
    image=image,
    timeout=300,
    runtime="vm",
    memory=8192,
    experimental_options={"vm_sidecar_memory_reserve_mib": 1024},
)

sidecar = sb._experimental_sidecars.create(
    "python",
    "-m",
    "http.server",
    "8080",
    name="web",
    image=image,
    experimental_memory_reserve_consume_mib=512,
)

# Omit experimental_memory_reserve_consume_mib to give this sidecar
# the remaining reserve (512 MiB here).
worker = sb._experimental_sidecars.create(
    "sleep", "600", name="worker", image=image
)
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image, {
  command: ["sleep", "600"],
  timeoutMs: 300 * 1000,
  runtime: "vm",
  memoryMiB: 8192,
  experimentalOptions: { vm_sidecar_memory_reserve_mib: "1024" },
});

const sidecar = await sb.experimentalSidecars.create("web", image, {
  command: ["python", "-m", "http.server", "8080"],
  experimentalMemoryReserveConsumeMiB: 512,
});

// Omit experimentalMemoryReserveConsumeMiB to give this sidecar
// the remaining reserve (512 MiB here).
const worker = await sb.experimentalSidecars.create("worker", image, {
  command: ["sleep", "600"],
});
```

{/snippet}

{#snippet go()}

```go notest
sb, _ := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Command:             []string{"sleep", "600"},
	Timeout:             5 * time.Minute,
	Runtime:             modal.SandboxRuntimeVM,
	MemoryMiB:           8192,
	ExperimentalOptions: map[string]any{"vm_sidecar_memory_reserve_mib": "1024"},
})

sidecar, _ := sb.ExperimentalSidecars.Create(ctx, "web", image, &modal.SidecarCreateParams{
	Command:                             []string{"python", "-m", "http.server", "8080"},
	ExperimentalMemoryReserveConsumeMiB: 512,
})
_ = sidecar

// Omit ExperimentalMemoryReserveConsumeMiB to give this sidecar
// the remaining reserve (512 MiB here).
worker, _ := sb.ExperimentalSidecars.Create(ctx, "worker", image, &modal.SidecarCreateParams{
	Command: []string{"sleep", "600"},
})
_ = worker
```

{/snippet} </CodeTabs>

Terminated VM Sidecars return their reserve for reuse by new Sidecars.

## Limitations

The main sandbox supports the same features as a regular sandbox, but some features are not yet supported
for sidecars:

* **Pre-built images only**: Sidecar images must already exist: pre-built with `image.build()`, a
  [named image](/docs/guide/named-images) via `Image.from_name()` after resolving it with `.build(app)`, an
  ID via `Image.from_id()`, or created from [filesystem](/docs/guide/sandbox-snapshots#filesystem-snapshots)/[directory](/docs/guide/sandbox-snapshots#directory-snapshots) snapshots. Lazy image
  building is not supported for sidecars. See also
  [Separating Image builds from Sandbox creation](/docs/guide/sandboxes#separating-image-builds-from-sandbox-creation).
* **No stdin/stdout**: A Sidecar's entrypoint does not expose stdin, stdout, or stderr streams.
* **Limitations on GPU Sandboxes**: You can attach Sidecars to Sandboxes with GPUs, but the Sidecar is CPU-only and cannot attach [Cloud Bucket Mounts](/docs/guide/cloud-bucket-mounts).
* **No memory snapshot support**: A Sidecar's [filesystem](/docs/guide/sandbox-snapshots#filesystem-snapshots) and [individual directories](/docs/guide/sandbox-snapshots#directory-snapshots) can be independently snapshotted, but Sidecar memory state can not be captured with a
  [memory snapshot](/docs/guide/sandbox-snapshots#memory-snapshots).
* **Sidecars bypass Connect Tokens**: a Sidecar can reach the main container's Connect Token port directly and set any
  `X-Verified-User-Data` header. See [Connect Tokens](#connect-tokens).
* **No `block_network` for Sidecars**: Sidecars can't be fully network-blocked,
  and their outbound network policy can't be changed after creation. See
  [Outbound access control](#outbound-access-control).
* **Changes to /etc/hosts are not preserved**: `/etc/hosts` is rewritten on sidecar create/terminate and user changes are not preserved.
