# Dedicated Endpoints

Dedicated Endpoints run
[supported models](/docs/guide/supported-models#dedicated-endpoint-models),
or compatible custom weights, on isolated, autoscaling containers. Use them
when you need control over autoscaling and regions, or dedicated capacity.

## Create a Dedicated Endpoint

The CLI creates Dedicated Endpoints by default:

```bash
modal endpoint create --name support-chat --model Qwen/Qwen3.5-4B
```

Modal resolves the model, selects a compatible serving recipe, and starts
provisioning. The command prints the Endpoint ID and a dashboard link where you
can watch it come online. Dedicated Endpoints can also be created from the
[**Endpoints**](https://modal.com/endpoints) tab in the dashboard.

When you create an Endpoint, Modal uses its name as the
[model name](/docs/guide/endpoints#model-names) that clients send as `model` in
requests.

## View the generated source

A Dedicated Endpoint is a Modal App built with the same primitives available in
the Modal SDK, including [`@app.server()`](/docs/guide/servers). Open the
**Source** view to inspect its generated `serve.py`. You can copy and adapt that
code into your own Modal App when you need full control of the serving stack.

## Serve custom weights

Custom weights use the serving recipe for a compatible
[Dedicated Endpoint model](/docs/guide/supported-models#dedicated-endpoint-models). Pass that model with `--model`,
then provide weights from Hugging Face or a Modal Volume.

From Hugging Face:

```bash
modal endpoint create \
  --name my-fine-tune \
  --model Qwen/Qwen3.6-27B \
  --custom-hf-repo aisingapore/Qwen-SEA-LION-v4.5-27B-IT \
  --custom-hf-revision da42f2c0984d716fb2032e4176d81adfac98c630
```

Use `--custom-hf-token` for gated or private repositories.

From a Modal Volume containing a `config.json` file:

```bash
modal endpoint create \
  --name my-volume-model \
  --model Qwen/Qwen3.5-4B \
  --custom-volume-name my-volume \
  --custom-volume-path /checkpoints/1234
```

## Configure capacity and placement

By default, Dedicated Endpoints scale up under load and down to zero when idle.
Configure minimum, maximum, and buffer containers from the dashboard.

The routing region controls where requests enter Modal. Compute placement
controls where containers run. Set them independently:

```bash
modal endpoint create \
  --model Qwen/Qwen3.5-4B \
  --routing-region us-east \
  --compute-region us-west
```

Use `--colocate-compute` instead to run compute in the routing region. Pinning
compute to a region incurs a
[region selection multiplier](/docs/guide/region-selection#pricing).

## Request routing

Dedicated Endpoints inherit the
[affinity routing](/docs/guide/servers#request-routing) of Servers:
requests that share a `Modal-Routing-Affinity-Key` header are routed to the same container
on a best-effort basis, which keeps a conversation's prompt prefix in that
container's cache. See
[Affinity routing](/docs/guide/endpoints#affinity-routing) for how to choose the
header value.

## Metrics

The **Activity** view shows request volume over time. Use **Responses** to inspect
individual requests and **Containers** to inspect the containers serving them.

For text-generation models, **Metrics** separates **Inference metrics**—latency,
throughput, running and queued requests, cache usage, and speculative
decoding—from **Server metrics** such as autoscaling and CPU, memory, network,
and GPU utilization.

## Benchmarks

For text-generation models, the **Benchmark** view can run a repeatable real-time
or agentic workload against the live Endpoint. Benchmarks generate traffic,
trigger autoscaling, and incur the usual compute cost.

Treat results as point-in-time measurements: fleet size, placement, and cold
starts can all affect them.

## Manage a Dedicated Endpoint

List Endpoints in an Environment:

```bash
modal endpoint list --env prod
```

Stop an Endpoint when you no longer need it:

```bash
modal endpoint stop my-endpoint --env prod
```

Stopping an Endpoint is permanent. It tears down the serving application and
deletes its managed model cache; the Endpoint cannot be restarted.

## Pricing

Dedicated Endpoints bill for the GPU, CPU, memory, and other resources used by
their containers at standard Modal compute rates. An Endpoint scaled to zero
does not incur compute charges.
