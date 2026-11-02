# Networking and security

Sandboxes are built to be secure-by-default, meaning that a default Sandbox has
no ability to accept incoming network connections or access your Modal resources.

## Outbound access control

By default, Sandboxes can make outbound connections to any public IP address.
Modal provides three levels of outbound network restriction:

| Level                         | Parameter                   | What it controls                                               |
| ----------------------------- | --------------------------- | -------------------------------------------------------------- |
| **Full block**                | `block_network=True`        | Drops all outbound traffic.                                    |
| **IP-range allowlist**        | `outbound_cidr_allowlist`   | Only allows traffic to the listed CIDR ranges (any protocol).  |
| **Domain allowlist** *(Beta)* | `outbound_domain_allowlist` | Only allows TLS traffic (port 443) to the listed domain names. |

`outbound_cidr_allowlist` and `outbound_domain_allowlist` can be combined additively - traffic that meets either criteria will be let through.

Sidecars have their own outbound network policy; see [Sandbox Sidecars →
Outbound access control](/docs/guide/sandbox-sidecars#outbound-access-control).

<Callout variant="warning">
Currently, DNS traffic is allowed without restriction except when all outbound traffic is blocked.
</Callout>

For advanced HTTPS inspection, the experimental `proxy_traffic_via_sidecar`
option routes outbound TCP traffic on port 443 from the main container through
a Sidecar. Relaying replaces the Sandbox's own controls on that traffic rather
than adding to them: an `outbound_cidr_allowlist` continues to govern every
other port, but stops applying to port 443, which is instead governed by the
Sidecar's egress controls. See [Routing HTTPS traffic through a
Sidecar](/docs/guide/sandbox-sidecars#routing-https-traffic-through-a-sidecar)
for details.

### Blocking all network access

Set `block_network=True` to prevent the Sandbox from making any outbound
connections:

<CodeTabs>
  {#snippet python()}

```python notest
sb = modal.Sandbox.create(
    "python", "my_script.py",
    block_network=True,
    app=app,
)
```

{/snippet}

{#snippet javascript()}

```javascript notest
import { ModalClient } from "modal";

const modal = new ModalClient();
const app = await modal.apps.fromName("sandbox-network", {
  createIfMissing: true,
});
const image = modal.images.fromRegistry("python:3.13-slim");
const sb = await modal.sandboxes.create(app, image, {
  command: ["python", "my_script.py"],
  blockNetwork: true,
});
await sb.terminate();
```

{/snippet}

{#snippet go()}

```go notest
package main

import (
	"context"

	modal "github.com/modal-labs/modal-client/go"
)

func main() {
	ctx := context.Background()
	mc, _ := modal.NewClient()
	app, _ := mc.Apps.FromName(ctx, "sandbox-network", &modal.AppFromNameParams{
		CreateIfMissing: true,
	})
	image := mc.Images.FromRegistry("python:3.13-slim", nil)
	sb, _ := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
		Command:      []string{"python", "my_script.py"},
		BlockNetwork: true,
	})
	sb.Terminate(ctx, nil)
}
```

{/snippet} </CodeTabs>

When `block_network` is enabled, `outbound_cidr_allowlist`,
`outbound_domain_allowlist`, and `inbound_cidr_allowlist` cannot be used.

### Restricting by IP range (CIDR allowlist)

Use `outbound_cidr_allowlist` to restrict outbound traffic to a set of IP
ranges. All traffic to IPs outside these ranges (except traffic allowed by `outbound_domain_allowlist`) is blocked.

<CodeTabs>
  {#snippet python()}

```python notest
sb = modal.Sandbox.create(
    "sleep", "infinity",
    outbound_cidr_allowlist=["52.0.0.0/8", "10.0.1.0/24"],
    app=app,
)
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image, {
  command: ["sleep", "infinity"],
  outboundCidrAllowlist: ["52.0.0.0/8", "10.0.1.0/24"],
});
```

{/snippet}

{#snippet go()}

```go notest
sb, err := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Command:               []string{"sleep", "infinity"},
	OutboundCIDRAllowlist: &modal.Allowlist{Entries: []string{"52.0.0.0/8", "10.0.1.0/24"}},
})
```

{/snippet} </CodeTabs>

### Restricting by domain name (domain allowlist)

<Callout variant="beta" />

Use `outbound_domain_allowlist` to restrict outbound TLS traffic to a set of
domain names:

<CodeTabs>
  {#snippet python()}

```python notest
sb = modal.Sandbox.create(
    "sleep", "infinity",
    outbound_domain_allowlist=["api.openai.com", "*.github.com"],
    app=app,
)
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image, {
  command: ["sleep", "infinity"],
  outboundDomainAllowlist: ["api.openai.com", "*.github.com"],
});
```

{/snippet}

{#snippet go()}

```go notest
sb, err := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Command:                []string{"sleep", "infinity"},
	OutboundDomainAllowlist: &modal.Allowlist{Entries: []string{"api.openai.com", "*.github.com"}},
})
```

{/snippet} </CodeTabs>

When a domain allowlist is set:

* **TLS (port 443)** connections are allowed only to the listed domains, or to
  IPs on a CIDR allowlist. Other connections are blocked and logged to the
  Sandbox's system output stream.
* **Non-TLS traffic** (HTTP, raw TCP, UDP) to IPs that are not on a CIDR
  allowlist is **blocked**.

Entries prefixed with `*.` match the parent domain and any subdomain:

| Allowlist entry | Matches                                           | Does not match    |
| --------------- | ------------------------------------------------- | ----------------- |
| `example.com`   | `example.com`                                     | `sub.example.com` |
| `*.example.com` | `example.com`, `a.example.com`, `a.b.example.com` | `evilexample.com` |

#### How domain filtering works

Domains are matched against the
[SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) in the TLS
handshake, and Modal resolves that hostname itself rather than trusting the
destination IP the Sandbox picked. TLS traffic is not decrypted, so the `Host`
header, URL path, and body are never inspected.

Encrypted Client Hello (ECH) is not supported. Modal only sees the outer public
name, not the real hostname inside it, so an ECH connection is matched against
that public name and is blocked unless the public name is on the allowlist.

<Callout variant="warning">

Two domains can share a TLS endpoint, such as two tenants of the same CDN. A
Sandbox can reach a non-allowlisted domain there by sending an allowlisted SNI
with the other name in the `Host` header, a technique called *domain fronting*.
Many providers reject mismatched requests, but the allowlist itself does not
prevent the mismatch.

If you need protection against domain fronting, consider using a
[Sidecar](/docs/guide/sandbox-sidecars) as a proxy.
[This example](/docs/examples/sidecar_traffic_routing) shows how to configure a
Sidecar as a domain allowlist.

</Callout>

### Updating the network policy at runtime

<Callout variant="alpha">

This API is experimental and has [limitations](#dynamic-policy-limitations) that
will be removed in a future release.

</Callout>

You can replace the outbound network policy of a running Sandbox without
restarting it. This is useful when an agent's trust level changes mid-session —
for example, starting with broad access while installing dependencies and then
locking down to only the domains a tool needs.

<CodeTabs>
  {#snippet python()}

```python notest
# Start with all outbound traffic allowed.
sb = modal.Sandbox.create(
    "sleep", "infinity",
    outbound_domain_allowlist=["*"],
    outbound_cidr_allowlist=["0.0.0.0/0"],
    app=app,
)

# ... later, narrow the policy to only the domains we need.
sb._experimental_set_outbound_network_policy(
    outbound_domain_allowlist=["api.openai.com", "*.github.com"],
)

# Or block all outbound traffic by passing empty allowlists.
sb._experimental_set_outbound_network_policy(
    outbound_domain_allowlist=[],
    outbound_cidr_allowlist=[],
)

# Widen back to allow-all when needed.
sb._experimental_set_outbound_network_policy(
    outbound_domain_allowlist=["*"],
    outbound_cidr_allowlist=["0.0.0.0/0"],
)
```

{/snippet}

{#snippet javascript()}

```javascript notest
// Start with all outbound traffic allowed.
const sb = await modal.sandboxes.create(app, image, {
  command: ["sleep", "infinity"],
  outboundDomainAllowlist: ["*"],
  outboundCidrAllowlist: ["0.0.0.0/0"],
});

// ... later, narrow the policy to only the domains we need.
await sb.updateNetworkPolicy({
  outboundDomainAllowlist: ["api.openai.com", "*.github.com"],
  outboundCidrAllowlist: [],
});

// Or block all outbound traffic by passing empty allowlists.
await sb.updateNetworkPolicy({
  outboundDomainAllowlist: [],
  outboundCidrAllowlist: [],
});

// Widen back to allow-all when needed.
await sb.updateNetworkPolicy({
  outboundDomainAllowlist: ["*"],
  outboundCidrAllowlist: ["0.0.0.0/0"],
});
```

{/snippet}

{#snippet go()}

```go notest
// Start with all outbound traffic allowed.
sb, err := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Command:                []string{"sleep", "infinity"},
	OutboundDomainAllowlist: &modal.Allowlist{Entries: []string{"*"}},
	OutboundCIDRAllowlist:   &modal.Allowlist{Entries: []string{"0.0.0.0/0"}},
})

// ... later, narrow the policy to only the domains we need.
err = sb.UpdateNetworkPolicy(ctx, &modal.SandboxUpdateNetworkPolicyParams{
	OutboundDomainAllowlist: &modal.Allowlist{Entries: []string{"api.openai.com", "*.github.com"}},
	OutboundCIDRAllowlist:   &modal.Allowlist{Entries: []string{}},
})

// Or block all outbound traffic by passing empty allowlists.
err = sb.UpdateNetworkPolicy(ctx, &modal.SandboxUpdateNetworkPolicyParams{
	OutboundDomainAllowlist: &modal.Allowlist{Entries: []string{}},
	OutboundCIDRAllowlist:   &modal.Allowlist{Entries: []string{}},
})

// Widen back to allow-all when needed.
err = sb.UpdateNetworkPolicy(ctx, &modal.SandboxUpdateNetworkPolicyParams{
	OutboundDomainAllowlist: &modal.Allowlist{Entries: []string{"*"}},
	OutboundCIDRAllowlist:   &modal.Allowlist{Entries: []string{"0.0.0.0/0"}},
})
```

{/snippet} </CodeTabs>

The new policy takes effect immediately. Established connections that the new
policy no longer permits are terminated.

#### Dynamic policy limitations

* Each allowlist type must be set at creation time to be usable later. To
  update `outbound_domain_allowlist` at runtime, the Sandbox must be created
  with `outbound_domain_allowlist` (e.g. `["*"]`). The same applies to
  `outbound_cidr_allowlist` — create with `["0.0.0.0/0"]` if you want to
  restrict by CIDR later.
* `block_network=True` is not compatible with this API. Use empty allowlists
  (`[]`) to block all traffic instead.

## Inbound access control

Use `inbound_cidr_allowlist` to restrict which IP addresses can connect
**inbound** to the Sandbox through encrypted tunnels and Sandbox Connect Tokens:

<CodeTabs>
  {#snippet python()}

```python notest
sb = modal.Sandbox.create(
    "python", "-m", "http.server", "8080",
    encrypted_ports=[8080],
    inbound_cidr_allowlist=["203.0.113.0/24"],
    app=app,
)
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image, {
  command: ["python", "-m", "http.server", "8080"],
  encryptedPorts: [8080],
  inboundCidrAllowlist: ["203.0.113.0/24"],
});
```

{/snippet}

{#snippet go()}

```go notest
sb, err := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Command:              []string{"python", "-m", "http.server", "8080"},
	EncryptedPorts:       []int{8080},
	InboundCIDRAllowlist: []string{"203.0.113.0/24"},
})
```

{/snippet} </CodeTabs>

`inbound_cidr_allowlist` is not enforced on unencrypted tunnels
(`unencrypted_ports`), which accept connections from any IP address. Use
`encrypted_ports` or `h2_ports` for ports that need to be restricted.

## Connecting to Sandboxes with HTTP and WebSockets

You can make authenticated HTTP and WebSocket requests to a Sandbox by generating
Sandbox Connect Tokens. They work like this:

<CodeTabs>
  {#snippet python()}

```python notest
# Start a Sandbox with a server running on port 8080.
sb = modal.Sandbox.create(
    "bash", "-c", "python3 -m http.server 8080",
    app=my_app,
)

# Create a connect token, optionally including arbitrary user metadata.
# Port 8080 is the default and could be omitted here.
creds = sb.create_connect_token(user_metadata={"user_id": "foo"}, port=8080)

# Make an HTTP request, passing the token in the Authorization header.
requests.get(creds.url, headers={"Authorization": f"Bearer {creds.token}"})

# You can also put the token in a `_modal_connect_token` query param.
url = f"{creds.url}/?_modal_connect_token={creds.token}"
ws_url = url.replace("https://", "wss://")
with websockets.connect(ws_url) as socket:
    socket.send("Hello world!")
```

{/snippet}

{#snippet javascript()}

```javascript notest
// Start a Sandbox with a server running on port 8080.
const sb = await modal.sandboxes.create(app, image, {
  command: ["bash", "-c", "python3 -m http.server 8080"],
});

// Create a connect token, optionally including arbitrary user metadata.
// Port 8080 is the default and could be omitted here.
const creds = await sb.createConnectToken({
  userMetadata: '{"user_id": "foo"}',
  port: 8080,
});

// Make an HTTP request, passing the token in the Authorization header.
const response = await fetch(creds.url, {
  headers: { Authorization: `Bearer ${creds.token}` },
});
```

{/snippet}

{#snippet go()}

```go notest
// Start a Sandbox with a server running on port 8080.
sb, err := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Command: []string{"bash", "-c", "python3 -m http.server 8080"},
})

// Create a connect token, optionally including arbitrary user metadata.
// Port 8080 is the default and could be omitted here.
creds, err := sb.CreateConnectToken(ctx, &modal.SandboxCreateConnectTokenParams{
	UserMetadata: `{"user_id": "foo"}`,
	Port:         8080,
})

// Make an HTTP request, passing the token in the Authorization header.
req, _ := http.NewRequestWithContext(ctx, "GET", creds.URL, nil)
req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", creds.Token))
resp, _ := http.DefaultClient.Do(req)
```

{/snippet} </CodeTabs>

The server running on the specified port in the container will receive an authenticated
request with an unspoofable `X-Verified-User-Data` header whose value is the
JSON-serialized metadata that was passed as `user_metadata` to
`create_connect_token()`. This can be used by the application to
determine access control, for example.

There are a few things to remember with Sandbox Connect Tokens:

1. By default, requests are routed to port 8080 in the container. Pass `port`
   to `create_connect_token()` to route to a different port.
2. The token may be sent in an `Authorization` header, in a `_modal_connect_token`
   query param, or in a `_modal_connect_token` cookie.
3. If `_modal_connect_token` is set as a query param, the resulting response will
   include a `Set-Cookie` header that sets it as a cookie.
4. The `user_metadata` must be JSON-serializable and must be less than 512
   characters after serialization.
5. The `user_metadata` is encoded into the connect token itself, so it
   should not contain secrets.

### Forwarding ports

While it is recommended to use [Sandbox Connect Tokens](#connecting-to-sandboxes-with-http-and-websockets)
for HTTP requests and WebSocket connections to the container, you can also expose
raw TCP ports to the internet. This is useful if, for example, you want to run a
server inside the Sandbox that expects a raw TCP connection and handles
authentication itself.

To forward ports, list them as encrypted or unencrypted ports when you create a
Sandbox. Then look up each port's tunnel to get its public URL:

<CodeTabs>
  {#snippet python()}

```python notest
import requests

sb = modal.Sandbox.create(
    "python",
    "-m",
    "http.server",
    "12345",
    encrypted_ports=[12345],
    readiness_probe=modal.Probe.with_tcp(12345),
    app=my_app,
)

# Blocks until port 12345 is accepting connections
sb.wait_until_ready()

tunnel = sb.tunnels()[12345]

print(f"Connecting to {tunnel.url}...")
print(requests.get(tunnel.url, timeout=5).text)
```

{/snippet}

{#snippet javascript()}

```javascript notest
import { Probe } from "modal";

const sb = await modal.sandboxes.create(app, image, {
  command: ["python", "-m", "http.server", "12345"],
  encryptedPorts: [12345],
  readinessProbe: Probe.withTcp(12345),
});

// Blocks until port 12345 is accepting connections
await sb.waitUntilReady();

const tunnel = (await sb.tunnels())[12345];

console.log(`Connecting to ${tunnel.url}...`);
const response = await fetch(tunnel.url);
console.log(await response.text());
await sb.terminate();
```

{/snippet}

{#snippet go()}

```go notest
probe, _ := modal.NewTCPProbe(12345, nil)
sb, _ := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Command:        []string{"python", "-m", "http.server", "12345"},
	EncryptedPorts: []int{12345},
	ReadinessProbe: probe,
})

// Blocks until port 12345 is accepting connections
sb.WaitUntilReady(ctx, 5*time.Minute, nil)

tunnels, _ := sb.Tunnels(ctx, 5*time.Minute, nil)
tunnel := tunnels[12345]

fmt.Printf("Connecting to %s...\n", tunnel.URL())
client := &http.Client{Timeout: 5 * time.Second}
response, _ := client.Get(tunnel.URL())
body, _ := io.ReadAll(response.Body)
response.Body.Close()
fmt.Println(string(body))
sb.Terminate(ctx, nil)
```

{/snippet} </CodeTabs>

To run an `HTTP/2` server inside a Sandbox, create an encrypted port that uses
`HTTP/2` instead of `HTTP/1.1`. Its tunnel URL accepts H2 (HTTP/2 + TLS)
requests:

<CodeTabs>
  {#snippet python()}

```python notest
port = 4359
sb = modal.Sandbox.create(
    app=my_app,
    image=my_image,
    h2_ports=[port],
)
p = sb.exec("python", "my_http2_server.py")

tunnel = sb.tunnels()[port]
print(f"Tunnel URL: {tunnel.url}")
```

{/snippet}

{#snippet javascript()}

```javascript notest
const port = 4359;
const sb = await modal.sandboxes.create(app, image, {
  h2Ports: [port],
});
const p = await sb.exec(["python", "my_http2_server.py"]);
const tunnel = (await sb.tunnels())[port];
console.log(`Tunnel URL: ${tunnel.url}`);
await sb.terminate();
```

{/snippet}

{#snippet go()}

```go notest
port := 4359
sb, _ := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	H2Ports: []int{port},
})
sb.Exec(ctx, []string{"python", "my_http2_server.py"}, nil)
tunnels, _ := sb.Tunnels(ctx, 5*time.Minute, nil)
tunnel := tunnels[port]
fmt.Printf("Tunnel URL: %s\n", tunnel.URL())
sb.Terminate(ctx, nil)
```

{/snippet} </CodeTabs>

For more details on how tunnels work, see the [tunnels guide](/docs/guide/tunnels).

### Custom domains

<Callout variant="gated-feature">

Custom domains for Sandbox tunnels are available on the <a href="/pricing">Team and Enterprise plans</a>. Visit <a href="/settings/plans">workspace settings</a> to upgrade.

</Callout>

<Callout variant="beta">

The infrastructure is production-grade, but onboarding requires a manual setup step.

</Callout>

By default, Sandbox tunnels are served from subdomains of `w.modal.host`.
In some cases, it's necessary to have a tunnel served through a custom domain
for security reasons. This is possible with manual setup.

Note that tunnel custom domains are distinct from other custom domains in Modal.
Other custom domains use `CNAME` forwarding. For tunnels, we need to use an
`NS` record to delegate the domain to Modal's nameservers.

**1. Delegate a (sub)domain to Modal's nameservers.**

Add `NS` records to your DNS zone pointing to Modal's nameservers. For example,
to use `sandbox.example.com`, add the following records in your DNS provider's
control panel:

| Name                  | Type | Value                |
| --------------------- | ---- | -------------------- |
| `sandbox.example.com` | NS   | `w-ns-a.modal.host.` |
| `sandbox.example.com` | NS   | `w-ns-b.modal.host.` |
| `sandbox.example.com` | NS   | `w-ns-c.modal.host.` |
| `sandbox.example.com` | NS   | `w-ns-d.modal.host.` |

You can delegate any subdomain depth you like (e.g. `tunnels.a.b.c.example.com`).

**2. Ask Modal to set up the domain.**

Reach out to us on Slack and provide the domain name. We'll enable it for your
workspace.

**3. Pass the custom domain when creating a Sandbox.**

<CodeTabs>
  {#snippet python()}

```python notest
import modal

app = modal.App.lookup("my-app", create_if_missing=True)
sb = modal.Sandbox.create(
    "python", "-m", "http.server", "8080",
    encrypted_ports=[8080],
    custom_domain="sandbox.example.com",
    app=app,
)

tunnel = sb.tunnels()[8080]
print(tunnel.url)  # https://[...].sandbox.example.com
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image, {
  command: ["python", "-m", "http.server", "8080"],
  encryptedPorts: [8080],
  customDomain: "sandbox.example.com",
});

const tunnel = (await sb.tunnels())[8080];
console.log(tunnel.url); // https://[...].sandbox.example.com
await sb.terminate();
```

{/snippet}

{#snippet go()}

```go notest
sb, _ := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Command:        []string{"python", "-m", "http.server", "8080"},
	EncryptedPorts: []int{8080},
	CustomDomain:   "sandbox.example.com",
})

tunnels, _ := sb.Tunnels(ctx, 5*time.Minute, nil)
tunnel := tunnels[8080]
fmt.Println(tunnel.URL()) // https://[...].sandbox.example.com
sb.Terminate(ctx, nil)
```

{/snippet} </CodeTabs>

Modal will provision a TLS certificate automatically. Sandbox Connect Tokens generated
for this sandbox will also use the custom domain.

## Security model

Modal Sandboxes are isolated from the host and from other workloads by one of the two
[runtimes](/docs/guide/sandboxes#runtimes) we offer:

* **gVisor**: [gVisor](https://gvisor.dev/) is a container runtime developed by Google
  that implements the Linux system call interface in userspace. System calls from
  the Sandbox are handled by gVisor instead of the host kernel, giving stronger
  isolation than normal container runtimes.
* **VMs**: the Sandbox runs in its own virtual machine with its own Linux
  kernel, isolated by the CPU's hardware virtualization through the Linux
  [KVM](https://docs.kernel.org/virt/kvm/index.html) hypervisor.

The [network access controls](#outbound-access-control) on this page apply to
both runtimes.

Additionally, Sandboxes are not authorized to access other resources in your Modal
workspace the way that Modal Functions are [by default](/docs/guide/restricted-access).
As a result, the blast radius of any malicious code will be limited to the Sandbox
itself.
