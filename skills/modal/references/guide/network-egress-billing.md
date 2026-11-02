# Network egress billing

## What is egress pricing?

Starting October 1, 2026, Modal charges for network egress. Network egress is
outbound network traffic measured from your Modal tasks. This includes traffic
sent through a container's network interface, private network traffic sent
directly to other Modal containers, and uploads through
[Cloud Bucket Mounts](/docs/guide/cloud-bucket-mounts). Reads from and writes to
Modal [Volumes](/docs/guide/volumes) do not count as network egress.

## What is the pricing?

| Plan       | Included per billing cycle | Additional egress |
| ---------- | -------------------------- | ----------------- |
| Starter    | 1 TiB                      | $0.04 per GiB     |
| Team       | 10 TiB                     | $0.04 per GiB     |
| Enterprise | 100 TiB                    | $0.04 per GiB     |

Every plan includes an egress allowance each billing cycle before charges apply.
Egress beyond the included amount is billed at $0.04 per GiB.

## How can I see my egress usage?

Visit the [Usage & Billing](/settings/usage?tab=usage) page and find the Network Egress
card. For the selected billing cycle, it shows:

* Your total egress and how much of the included allowance you've used
* An estimated charge based on your current plan
* Egress for the whole Workspace, broken down by day, which you can filter by Environment
* The Apps with the most egress

Egress costs are also included in the Modal CLI and SDK, for example:

* `modal billing summary`: Workspace spend, including egress and the allowance
* `modal billing report --for "this month" --show-resources`: egress cost per App
* `modal environment billing summary`: egress cost for one Environment
* `modal billing rates`: your plan's egress rate

In the SDK, use [`Workspace.billing`](/docs/sdk/py/latest/Workspace#billing)
and [`Environment.billing`](/docs/sdk/py/latest/Environment#billing).

## Is the allowance applied separately to each Environment?

No. The allowance applies once to total egress across the entire Workspace.
Environment filters on the Usage & Billing page show how much usage occurred in
a particular Environment, but they do not provide a separate allowance or an
independent charge estimate. To see the estimated Workspace charge, select all
Environments.

## What is the timeline for these changes?

Starting September 1, 2026, network egress usage appears live on your Usage &
Billing page, including your daily egress amount and estimated charge. You are
not charged for egress in September.

Starting October 1, 2026, egress is charged. Your first bill including egress
arrives on November 1, 2026.

## Do writes to Modal Volumes count as network egress?

No. Reads from and writes to Modal Volumes do not count as network egress.

Transferring that data elsewhere — for example, uploading it from a Modal
Function to an external API or object store — does count as egress. Reusing data
stored in a Volume can avoid repeated external transfers.

## How can I lower my egress usage?

Focus on bytes your workloads send through direct network connections:

* Compress large uploads to external APIs and object storage.
* Remove unnecessary response fields, paginate large results, and avoid
  duplicate uploads or retries.
* Cache models, datasets, or dependencies in Images or Volumes to reduce
  repeated downloads and startup time. Because downloads are ingress, this does
  not by itself reduce metered egress.
* Cloud Bucket Mount uploads count as egress. Downloads are primarily ingress,
  although outbound request and protocol bytes may still be measured.
* Keep producer and consumer logic in the same process or container when
  practical, so intermediate data does not cross a network interface.
* Avoid uploading intermediate artifacts to an external service only for another
  Modal task to download them again.
