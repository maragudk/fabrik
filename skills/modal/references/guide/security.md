# Security and privacy at Modal

This page outlines Modal's security and privacy commitments.

Our [Trust Center](https://trust.modal.com/) provides [compliance](#compliance-standards) documentation, including our SOC 2 Type II report, our list of subprocessors, and details of our security controls.

## Information security program

Our information security (InfoSec) program covers three practice areas: application security, corporate security, and network and infrastructure security.

<Collapsible title="Application security (AppSec)">

AppSec covers how we build, test, review, and deploy the Modal platform.

* We build our software using memory-safe programming languages, including Rust (for our worker runtime and storage infrastructure) and Python (for our API servers and Modal client).
* Software dependencies are automatically audited for known vulnerabilities.
* We make decisions that minimize our attack surface. Most interactions with Modal are well-described in a gRPC API, and occur through [`modal`](https://pypi.org/project/modal), our open-source command-line tool and Python client library.
* We have automated synthetic monitoring test applications that continuously check for network and application isolation within our runtime.
* We force HTTPS (TLS) for all services, including our public website and the Dashboard. Our [client library](https://pypi.org/project/modal) connects to Modal's servers over TLS and verifies TLS certificates on each connection.
* Your data is encrypted in transit and at rest.
* All public Modal APIs use [TLS 1.3](https://datatracker.ietf.org/doc/html/rfc8446).
* Internal code reviews are performed using a PR-based development workflow, and we engage external penetration testing firms to assess our software security.

</Collapsible>

<Collapsible title="Corporate security (CorpSec)">

CorpSec covers how our employees access internal systems.

* Access to internal systems requires single sign-on (SSO) through our identity provider.
* Phishing-resistant multi-factor authentication (MFA) is required for all employee accounts.
* We regularly audit access to internal systems.
* Employee laptops are enrolled in mobile device management (MDM) with full disk encryption enforced.

</Collapsible>

<Collapsible title="Network and infrastructure security (InfraSec)">

InfraSec covers how we secure the infrastructure that runs your workloads.

* We continuously monitor platform logs and metrics through third-party observability providers.
* Each container runs in its own sandbox, isolated from the host, using primitives like [gVisor](https://github.com/google/gvisor) or microVMs.
* We run business continuity and security incident exercises every year.

</Collapsible>

### Vulnerability remediation

We remediate vulnerabilities in Modal's systems within the timeframes below, measured from when a fix becomes available. Severity is based on the CVSS rating of the vulnerability and our assessment of its impact on Modal.

#### Severity timeframes

* **Critical:** 24 hours
* **High:** 1 week
* **Medium:** 1 month
* **Low:** 3 months
* **Informational:** 3 months or longer

### Bug bounty program

We welcome responsible disclosure from the security community and run a private bug bounty program through HackerOne. To participate, email <security@modal.com> with your HackerOne username and we will send an invite. When performing security research, you must use a Modal Workspace whose name ends in `-H1-<username>`, where `<username>` is your HackerOne username.

## Data privacy

This section covers how long each type of data is kept, which products retain no data at all, and where your data is stored.

### Data retention

Retention varies by product; the table below shows how long each type of data is retained. All stored data is encrypted at rest.

| Data                                  | Product                                                                                                            | Retention                                                                                               |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------- |
| Inputs and outputs                    | [Functions](/docs/guide) (`.remote`, `.spawn`, `.map`, [Web Functions](/docs/guide/webhooks), Scheduled Functions) | Up to 7 days, then deleted                                                                              |
| Request and response payloads         | [Server](/docs/guide/servers) and [Auto Endpoints](/docs/guide/endpoints)                                          | Not stored — proxied directly to your container                                                         |
| App and container logs                | [Functions](/docs/guide), [Sandboxes](/docs/guide/sandboxes)                                                       | Plan-dependent: 1 day on Starter, 30 days on Team, configurable on Enterprise (see [pricing](/pricing)) |
| Audit logs                            | Workspace (Enterprise)                                                                                             | Per Enterprise contract (see [Audit logs](/docs/guide/audit-logs))                                      |
| Files                                 | [Volumes](/docs/guide/volumes), [Images](/docs/guide/images)                                                       | Persistent until you delete them                                                                        |
| Function memory snapshots             | [Functions](/docs/guide/memory-snapshots)                                                                          | 30 days after creation                                                                                  |
| Sandbox memory snapshots              | [Sandboxes](/docs/guide/sandbox-snapshots)                                                                         | 7 days after creation                                                                                   |
| Filesystem snapshots                  | [Sandbox filesystem snapshots](/docs/guide/sandbox-snapshots)                                                      | 30 days after creation (configurable; stored as Images)                                                 |
| Directory snapshots                   | [Sandbox directory snapshots](/docs/guide/sandbox-snapshots)                                                       | 30 days after creation (configurable)                                                                   |
| Entries                               | [Dicts](/docs/guide/dicts)                                                                                         | 7 days after last read or write                                                                         |
| Partitions                            | [Queues](/docs/guide/queues)                                                                                       | Configurable per-partition TTL (default 24 hours)                                                       |
| App, Function, and container metadata | All products                                                                                                       | Stored for the lifetime of your account                                                                 |

<Callout variant="info">

While we store app logs and metadata as part of operating the platform, we access them only with your permission, to help troubleshoot an issue.

</Callout>

### Zero data retention

[Dedicated](/docs/guide/dedicated-endpoints) and [Shared](/docs/guide/shared-endpoints) inference endpoints have zero data retention. Request and response payloads are never written to disk and pass through Modal only as in-flight network traffic.

### Data residency

See our [data residency guide](/docs/guide/data-residency) for where each type of data is stored and the controls available for residency requirements.

## Shared responsibility model

Modal prioritizes the integrity, security, and availability of customer data. Under our shared responsibility model, you also have responsibilities in the areas below.

| Area                            | Modal                                                                                                                                                                                             | Customer                                                                                                                                                                                                                              |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Access and secrets              | Provides access controls, including SSO, SCIM, API tokens, and RBAC, and [Secrets](/docs/guide/secrets) management for storing credentials.                                                       | Manage the identities in your Workspace, assign roles, and rotate and remove API tokens. Own the contents and rotation of your Secrets.                                                                                               |
| Encryption and network security | Encrypts data in transit with TLS 1.3 and at rest.                                                                                                                                                | Decide which endpoints you expose and how they are authenticated. Apply any additional encryption your data requires, such as encrypting sensitive fields before they reach Modal.                                                    |
| Vulnerabilities                 | Patches the platform and runtimes within our [severity timeframes](#severity-timeframes) and audits our dependencies for known vulnerabilities.                                                   | Patch your Images, dependencies, and code.                                                                                                                                                                                            |
| Untrusted code                  | Provides isolation primitives for running untrusted code through [Restricted Functions and Sandboxes](/docs/guide/restricted-access#sandboxes-offer-an-alternative-interface-for-untrusted-code). | Run untrusted code, such as LLM-generated or end-user-submitted code, using those primitives and with guardrails such as egress restrictions, resource limits, and timeouts. Keep Secrets and credentials out of untrusted workloads. |
| Data lifecycle                  | Ensures the durability of managed storage and applies our [retention](#data-retention) and deletion policies.                                                                                     | Maintain backups of the data you store in Modal and routinely verify their integrity.                                                                                                                                                 |
| Operations                      | Operates the platform for high availability, monitors it, and responds to platform incidents.                                                                                                     | Monitor your applications and design for failover.                                                                                                                                                                                    |
| Compliance                      | Makes our audit reports and control documentation available on our [Trust Center](https://trust.modal.com).                                                                                       | Determine which laws and regulations apply to your organization and your data, and configure and use Modal to meet them.                                                                                                              |

### Security features

We provide security features across our products to help you secure your workloads, such as single sign-on, Role-Based Access Control (RBAC), Sandbox network access controls, audit logs, and customer-supplied encryption keys.

| Product       | Features                                                                                                                                                                                                                 |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Workspace     | [Block unauthenticated endpoints](/docs/guide/webhook-proxy-auth#blocking-unauthenticated-urls), [Role-Based Access Control (RBAC)](/docs/guide/rbac), [Proxies (static egress IPs)](/docs/guide/proxy-ips)              |
| Functions     | [Restricted Functions](/docs/guide/restricted-access)                                                                                                                                                                    |
| Sandboxes     | [Outbound access control](/docs/guide/sandbox-networking#outbound-access-control), [Inbound access control](/docs/guide/sandbox-networking#inbound-access-control)                                                       |
| Identity      | [Okta SSO](/docs/guide/okta-sso), [Microsoft Entra SSO](/docs/guide/entra-sso), [Custom SAML SSO](/docs/guide/saml-sso), [SCIM integration](/docs/guide/scim?idp=okta), [OIDC integration](/docs/guide/oidc-integration) |
| Observability | [Audit logs](/docs/guide/audit-logs), [Datadog integration](/docs/guide/datadog-integration), [OpenTelemetry integration](/docs/guide/otel-integration)                                                                  |
| Encryption    | [Customer-supplied encryption keys](/docs/guide/customer-supplied-encryption-keys)                                                                                                                                       |

## Compliance standards

### System and Organization Controls (SOC) 2 Type II

For our latest SOC 2 Type II audit report, please visit our [Trust Center](https://trust.modal.com) to request access.

### General Data Protection Regulation (GDPR)

A Data Processing Addendum (DPA) is available on our [Trust Center](https://trust.modal.com).

### Health Insurance Portability and Accountability Act (HIPAA)

<Callout variant="gated-feature">
Contact <a href="mailto:sales@modal.com">sales@modal.com</a> to get started with HIPAA on the <a href="/pricing">Enterprise plan</a>.
</Callout>

The following products are out of scope and should not be used for protected health information (PHI):

| Out of scope for PHI                             | Notes                                                                         |
| ------------------------------------------------ | ----------------------------------------------------------------------------- |
| [Volumes v1](/docs/guide/volumes)                | Use [Volumes v2](/docs/guide/volumes#volumes-v2) instead                      |
| [Images](/docs/guide/images)                     | Excluding [Filesystem and Directory Snapshots](/docs/guide/sandbox-snapshots) |
| [Memory Snapshots](/docs/guide/memory-snapshots) | —                                                                             |
| User code                                        | —                                                                             |

## Contact

<security@modal.com>
