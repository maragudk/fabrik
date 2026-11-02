# Sandbox Secret Injection

<Callout variant="beta">

This feature is experimental and the API is subject to change. There are
currently several [known limitations](#limitations).

</Callout>

An Outbound Policy lets a Sandbox call external HTTPS APIs that require
authentication without the API key ever being visible inside the Sandbox.

Sandboxes are often used to run untrusted code. Passing API keys to such code
as environment variables is risky: any process in the Sandbox can read its own
environment and exfiltrate the keys. An Outbound Policy avoids this by
declaring headers replacements which are injected into outbound HTTPS requests
to given domains. This replacement happens outside the Sandbox so the secret
never appears in the Sandbox's environment.

For a complete working demonstration, see the [Outbound Policy
example](/docs/examples/sandbox_secret_injection).

## Defining an Outbound Policy

An Outbound Policy is an immutable configuration object built by chaining
`with_header_replacement` calls. Each call adds a domain, a set of headers to
inject into requests to that domain, and optionally a
[Secret](/docs/guide/secrets) whose keys can be referenced in the header
values.

<CodeTabs>
  {#snippet python()}

```python notest
import modal
import modal.experimental

secret = modal.Secret.from_name("api-token")

outbound_policy = (
    modal.experimental.OutboundPolicy()
    # Inject a secret-backed Authorization header.
    .with_header_replacement(
        domain="example.com",
        secret=secret,
        headers={"Authorization": "Bearer $API_TOKEN"},
    )
    # Inject a static header into requests to another domain.
    .with_header_replacement(
        domain="modal.com",
        headers={"X-Trace-Token": "trace_abcd"},
    )
)
```

{/snippet}

{#snippet javascript()}

```javascript notest
import { ExperimentalOutboundPolicy, ModalClient } from "modal";

const modal = new ModalClient();
const secret = await modal.secrets.fromName("api-token");

const outboundPolicy = new ExperimentalOutboundPolicy()
  // Inject a secret-backed Authorization header.
  .withHeaderReplacement({
    domain: "example.com",
    secret,
    headers: { Authorization: "Bearer $API_TOKEN" },
  })
  // Inject a static header into requests to another domain.
  .withHeaderReplacement({
    domain: "modal.com",
    headers: { "X-Trace-Token": "trace_abcd" },
  });
```

{/snippet}

{#snippet go()}

```go notest
secret, err := mc.Secrets.FromName(ctx, "api-token", nil)
if err != nil {
	return err
}

outboundPolicy := new(modal.ExperimentalOutboundPolicy).
	// Inject a secret-backed Authorization header.
	WithHeaderReplacement(modal.ExperimentalOutboundPolicyHeaderReplacement{
		Domain:  "example.com",
		Secret:  secret,
		Headers: map[string]string{"Authorization": "Bearer $API_TOKEN"},
	}).
	// Inject a static header into requests to another domain.
	WithHeaderReplacement(modal.ExperimentalOutboundPolicyHeaderReplacement{
		Domain:  "modal.com",
		Headers: map[string]string{"X-Trace-Token": "trace_abcd"},
	})
```

{/snippet} </CodeTabs>

A Outbound Policy can contain up to 25 header values across all header
replacement added to it.

### Domain matching

Each header replacement's `domain` supports exact hostnames, `*.` wildcard
prefixes, and a bare `"*"`:

| Domain entry    | Matches                                           | Does not match    |
| --------------- | ------------------------------------------------- | ----------------- |
| `example.com`   | `example.com`                                     | `sub.example.com` |
| `*.example.com` | `example.com`, `a.example.com`, `a.b.example.com` | `evilexample.com` |
| `*`             | any domain                                        | —                 |

Multiple replacement entries may cover the same domain. All matching
replacements apply in the order they were added. An injected header replaces
any header with the same name that existed on the request, either set by the
Sandbox workload or any previously matched replacements.

### Header value templates

Header values support templating against the keys of a supplied Secret.
A `$`-prefixed key name is replaced with the secret value at request time.
To write a literal `$`, escape it as `$$`.

A replacement without a `secret` is static, and its header values are used
verbatim when injected into the request.

## Attaching a policy to a Sandbox

Pass the policy to `Sandbox.create`:

<CodeTabs>
  {#snippet python()}

```python notest
sb = modal.Sandbox.create(
    "python", "agent.py",
    app=app,
    _experimental_outbound_policy=outbound_policy,
)
```

{/snippet}

{#snippet javascript()}

```javascript notest
const sb = await modal.sandboxes.create(app, image, {
  command: ["python", "agent.py"],
  experimentalOutboundPolicy: outboundPolicy,
});
```

{/snippet}

{#snippet go()}

```go notest
sb, err := mc.Sandboxes.Create(ctx, app, image, &modal.SandboxCreateParams{
	Command:        []string{"python", "agent.py"},
	ExperimentalOutboundPolicy: &outboundPolicy,
})
```

{/snippet} </CodeTabs>

This policy is invisible from the Sandbox: none of the secrets used in any
header replacements are added to the Sandbox environment.

## Updating the policy on a running Sandbox

You can replace the Outbound Policy on a running Sandbox without restarting it.
Updating the policy will fully replace the existing one previously configured.

<CodeTabs>
  {#snippet python()}

```python notest
sb._experimental_update_outbound_policy(
    outbound_policy.with_header_replacement(
        domain="*",
        headers={"X-Sandbox-Id": sb.object_id},
    )
)
```

{/snippet}

{#snippet javascript()}

```javascript notest
await sb.experimentalUpdateOutboundPolicy(
  outboundPolicy.withHeaderReplacement({
    domain: "*",
    headers: { "X-Sandbox-Id": sb.sandboxId },
  }),
);
```

{/snippet}

{#snippet go()}

```go notest
updated := outboundPolicy.WithHeaderReplacement(modal.ExperimentalOutboundPolicyHeaderReplacement{
	Domain:  "*",
	Headers: map[string]string{"X-Sandbox-Id": sb.SandboxID},
})
err := sb.ExperimentalUpdateOutboundPolicy(ctx, &updated)
if err != nil {
	return err
}
```

{/snippet} </CodeTabs>

Updating the policy only works if the Sandbox was created with an Outbound
Policy. If you want to update the policy later you can create a Sandbox with an
empty Outbound Policy.

## How it works

When a Sandbox is created with an Outbound Policy, Modal attaches a small proxy
that sits on the Sandbox's outbound network path.

Outbound TCP traffic on port 443 is redirected through the proxy, which reads
the destination domain from the
[SNI](https://en.wikipedia.org/wiki/Server_Name_Indication) in the TLS
handshake.

If the domain matches a policy rule, the proxy **terminates the TLS
connection** using a certificate minted by certificate authority (CA) unique to
the Sandbox. The CA's certificate is installed into the Sandbox's trust store
at creation time, see [TLS trust inside the
Sandbox](#tls-trust-inside-the-sandbox). The proxy injects the configured
headers and forwards the request to the destination over a separate TLS
connection.

If the domain does not match any rule, the connection is passed through
untouched.

Only HTTPS on port 443 is eligible for injection. Plain HTTP, other ports, and
non-TLS protocols are never terminated or modified. Connections using
Encrypted Client Hello (ECH) hide their real destination from the proxy and
are passed through without injection.

## TLS trust inside the Sandbox

TLS termination only works if the workload trusts the Certificate Authority
used in the proxy. At creation time Modal installs the CA certificate in the
root filesystem at `/etc/modal/sandbox-egress-ca.crt`. We also try to
append this to any existing system CA bundle the image has if we can recognize
it.

Modal also sets common environment variables in the Sandbox pointing towards
a CA bundle containing the Sandbox CA certificate:

* `SSL_CERT_FILE`
* `REQUESTS_CA_BUNDLE`
* `CURL_CA_BUNDLE`
* `NODE_EXTRA_CA_CERTS`

If your chosen HTTP client does not recognize these environment variables, or
if your system CA bundle is in a location where we don't append the CA
certificate, you will need to manually configure the client to read the
certificate from `/etc/modal/sandbox-egress-ca.crt`.

## Limitations

There are some known limitations to this feature. We are working on improving
this feature, but for now we are aware that the following does not work:

* We only support HTTP/1.1 in both directions. The proxy installed will only
  advertise HTTP/1.1 over [ALPN](https://en.wikipedia.org/wiki/Application-Layer_Protocol_Negotiation)
  and will only use HTTP/1.1 when forwarding the connection to the destination.
  This means that HTTP/2-only traffic, including gRPC, will not work.
* Only named Secrets will work. Ephemeral Secrets (`Secret.from_dict`) are not
  supported yet.
* An Outbound Policy cannot be combined with `block_network`,
  `outbound_domain_allowlist`, `outbound_cidr_allowlist`, the experimental
  `proxy_traffic_via_sidecar` option, or [memory
  snapshots](/docs/guide/sandbox-snapshots) (`enable_snapshot`).
* An Outbound Policy can only be applied to the main Sandbox container.
  [Sidecar](/docs/guide/sandbox-sidecars) containers are not covered.
* Secret values are resolved when the Sandbox is created and on each
  `_experimental_update_outbound_policy` call. A running Sandbox will not pick up new values
  if the Secret is updated after this.
