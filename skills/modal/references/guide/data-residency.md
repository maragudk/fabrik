# Data residency on Modal

This page explains how to control where your Modal workloads run, under what circumstances customer data may leave your region, and when additional data containing customer data may be created and stored outside of your region. It also outlines general strategies for meeting your regional compliance requirements.

## Region selection

You can select the container and routing regions for most Modal services.

* **Container region**‡ is where workload containers run and application code processes data.
* **Routing region** is where requests enter Modal's network before being forwarded to your containers. As a general rule, we recommend choosing the routing region closest to your clients.

For a full list of available regions, please visit our [region selection documentation](/docs/guide/region-selection) page.

‡ *Functions and Sandboxes set the container region with `region=`; Servers use `compute_region=`, and Endpoints use `--compute-region`.*

| **Service**                                              | **Selectable container region?**                                        | **Selectable routing region?**                                          |
| -------------------------------------------------------- | ----------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| [Endpoints (Dedicated)](/docs/guide/dedicated-endpoints) | [Yes](/docs/guide/dedicated-endpoints#configure-capacity-and-placement) | [Yes](/docs/guide/dedicated-endpoints#configure-capacity-and-placement) |
| [Endpoints (Shared)](/docs/guide/shared-endpoints)\*     | No                                                                      | No                                                                      |
| [Functions](/docs/guide/functions)                       | [Yes](/docs/guide/region-selection#specifying-a-container-region)       | [Yes](/docs/guide/region-selection#regional-routing)                    |
| [Sandboxes](/docs/guide/sandboxes)                       | [Yes](/docs/guide/region-selection#specifying-a-container-region)       | N/A†                                                                    |
| [Servers](/docs/guide/servers)                           | [Yes](/docs/guide/servers#request-routing)                              | [Yes](/docs/guide/servers#request-routing)                              |

\* *Shared Endpoints route through `us-west`, and containers are distributed across Modal's global compute pool.*

† *Sandboxes don't use a routing region: data-plane requests (including encrypted tunnels, Sandbox Connect Tokens, `exec` input/output) go directly to the container in your selected region. Sandbox lifecycle requests (e.g. create and terminate) are routed through our control plane in `us-east`.*

### Region pinning is strict

Workloads pinned to a routing region route traffic only through that region, and workloads pinned to a container region run only on compute in that region; neither is ever moved elsewhere, even if the region runs out of capacity.

Pinning your containers to fewer regions gives you certainty about where your workloads run, but at the cost of a smaller pool of capacity to scale into. In addition, pinning a container region will apply a multiplier on top of our base usage pricing; see [region selection pricing](/docs/guide/region-selection#pricing) for more details.

Before pinning the region of your containers, we recommend assessing which workloads require strict data residency. Workloads that do not can take advantage of Modal's global pool of compute for higher availability.

## Where data is stored

In this section, we'll outline where logs and other data may be stored for different Modal products. For relevant retention policies, please refer to the data retention table in our [security and privacy documentation](/docs/guide/security#data-retention).

Dedicated Endpoints, Shared Endpoints, and Servers do not [store request and response payloads](/docs/guide/security#zero-data-retention).

| Product                           | Data type                                                                 | Where                                                       | Recommended controls for strict residency requirements                                                                                                                                                                                                                                                |
| --------------------------------- | ------------------------------------------------------------------------- | ----------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Functions, Sandboxes, and Servers | Application logs (`stderr` and `stdout`)                                  | United States                                               | Ensure that production code is not writing sensitive customer data to application logs.                                                                                                                                                                                                               |
| Functions                         | Synchronous payloads 2 MiB or smaller                                     | Routing region (`us-east` if no routing region is selected) | Ensure that you select a routing region when creating your Functions.                                                                                                                                                                                                                                 |
| Functions                         | Payloads over 2 MiB, and spawned (asynchronous) call payloads of any size | United States                                               | Reduce the size of Function I/O, or use Cloud bucket mounts to read and write inputs and outputs.                                                                                                                                                                                                     |
| Sandboxes                         | Snapshots you explicitly create                                           | United States                                               | Create snapshots before introducing customer data.                                                                                                                                                                                                                                                    |
| Storage products                  | Data written to Volumes, Images, Dicts, Queues, and Secrets               | United States                                               | Use Cloud bucket mounts as an alternative durable storage location for Volumes. For Dicts and Queues, use comparable technologies hosted in your own region, such as a managed key-value store or message queue. Avoid storing customer data with strict residency requirements in Images or Secrets. |

### Data at rest in durable storage products

Durable storage for Images, Volumes, Dicts, Queues, and Secrets resides in object storage located in the United States.

For durable storage, such as Volumes, you can opt to bring your own storage via [Cloud bucket mounts](/docs/guide/cloud-bucket-mounts), which support various cloud provider buckets in the region of your choice.

## Compliance

Modal allows you to meet your regional data residency and privacy requirements by giving you control over how your customer data flows through the platform. This includes controlling where your Modal workloads run, under what circumstances your customer data may leave your region, and when additional data containing customer data may be created and stored outside of your region.

Per our [shared responsibility model](/docs/guide/security#shared-responsibility-model), it is your responsibility to set the configuration to meet your obligations, such as General Data Protection Regulation (GDPR) compliance.

For more information, please see our Security Portal at [trust.modal.com](https://trust.modal.com/).

### Meeting your regional compliance requirements

We recommend starting by understanding your compliance requirements in relation to how you use Modal. Regulations like GDPR apply based on how and where you use Modal, so it's important to work out your obligations for data storage, processing, and transfer before designing your workloads, and to ask your legal or compliance team how those obligations map to your data flows.

Below, we outline strategies for controlling where your workloads run, what data leaves your region, and what new customer data is created.

### Controlling where your workloads run

* **Pin container and routing regions when you have strict residency requirements.** Select container and routing regions for supported products at creation time. Region selection is strict: workloads pinned to a region will only run there. For the capacity and pricing tradeoffs, see [Region pinning is strict](#region-pinning-is-strict) above.

### Controlling what customer data leaves your region

* **Bring your own storage.** You can mount your own object storage, such as an Amazon S3 bucket in your region, into your containers with a [Cloud bucket mount](/docs/guide/cloud-bucket-mounts). Data at rest then stays in your region, under your own retention and access policies.
* **Use synchronous calls and keep Function inputs and outputs 2 MiB or smaller so payloads are persisted in your routing region.** On Functions, synchronous payloads (those sent via `.remote()` / `.map()` or Web Functions) 2 MiB or smaller stay in the routing region. Larger payloads, and all spawned (asynchronous) call payloads regardless of size, are kept in Modal's centralized US storage.
  * If you need payloads to stay in a specific region, we recommend passing a reference (such as an object key) instead of the data itself, and reading and writing the actual data via your own mounted storage as described above. This keeps input and output data out of regional data stores and central storage entirely.
* **Use regional proxies if your use case requires static egress IPs.** If you use [Modal Proxies](/docs/guide/proxy-ips) for static egress IPs, that traffic routes through the proxy region regardless of your container region. Data is encrypted in transit.
* **Use encrypted tunnels when tunnel traffic must stay in your region.** Encrypted tunnels are served directly from your selected container region. Unencrypted tunnels route through relay servers in various geographical regions, so avoid them for traffic with residency requirements.

### Controlling what new customer data gets created

* **Sanitize sensitive data from logs.** Anything your code writes to `stdout`/`stderr` is stored as logs in Modal's centralized US data stores and retained based on our published data retention table. For applications processing customer data, ensure the data is never logged and never leaked through error handling. Unhandled exception tracebacks, for example, are written to `stderr` and end up in logs.
* **Account for snapshots in your data flows.** Sandbox snapshots are only created when you explicitly request them, but when you do, they are stored in the United States regardless of where your workloads run. A memory snapshot captures a Sandbox's entire state, including any sensitive data held in memory at snapshot time. Filesystem snapshots are stored as Modal Images under the hood, so the same US-residency considerations apply to any Image used to boot Modal containers.
