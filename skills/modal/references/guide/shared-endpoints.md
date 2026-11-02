# Shared Endpoints

Shared Endpoints serve a subset of
[supported models](/docs/guide/supported-models#shared-endpoint-models) from
Modal-managed pools. Modal manages the hardware and autoscaling, and usage is
billed per token.

## Create a Shared Endpoint

Pass `--shared` to create a Shared Endpoint from the CLI:

```bash
modal endpoint create --shared --model moonshotai/Kimi-K3
```

Shared Endpoints can also be created from the
[**Endpoints**](https://modal.com/endpoints) tab in the dashboard.

Once the Endpoint is ready, the dashboard provides its URL, model name, and
request examples. Shared Endpoints always require a
[proxy token](/docs/guide/endpoints#proxy-tokens).

## Concurrency limits

Shared Endpoints have model-specific limits on concurrent in-flight requests.
The limit is shared across all Shared Endpoints using the same model in your
Workspace. Requests above the limit receive an HTTP `429` response; retry them
with exponential backoff and jitter.

Use a [Dedicated Endpoint](/docs/guide/dedicated-endpoints) when you need
isolated or configurable capacity.

## Request routing

Shared Endpoints route each request to the container most likely to have its
prompt prefix cached. For multi-turn conversations and agent loops, send a
`Modal-Routing-Affinity-Key` header with every request of a conversation so its requests
stay on the same container. See
[Affinity routing](/docs/guide/endpoints#affinity-routing) for how to choose the
header value.

## Pricing

Token rates for each model are listed in
[supported models](/docs/guide/supported-models#shared-endpoint-models), and are
shown when you create an Endpoint and in its Usage view. Credits
included with your plan cannot be used for Shared Endpoint usage. To cap
out-of-pocket charges, see [spend limits](/docs/guide/budgets#spend-limits).

Shared Endpoint requests route through `us-west` and always require
authentication. Modal manages their infrastructure and capacity.
