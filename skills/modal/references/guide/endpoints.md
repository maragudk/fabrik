# Endpoints

Modal Endpoints let you deploy
[supported open models](/docs/guide/supported-models)—or your own custom
weights—as production-ready inference APIs.

* **Fast inference** — tuned open-source serving engines, with speculative
  decoding where supported, behind Modal's low-latency request proxy.
* **Managed infrastructure** — Modal handles provisioning, routing, and
  capacity management.
* **Open and inspectable** — use familiar OpenAI- and Anthropic-compatible APIs;
  [inspect or adapt the generated source](/docs/guide/dedicated-endpoints#view-the-generated-source)
  behind a Dedicated Endpoint.

Choose between two serving modes:

|              | [Shared Endpoints](/docs/guide/shared-endpoints)                     | [Dedicated Endpoints](/docs/guide/dedicated-endpoints)                                          |
| ------------ | -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| **Best for** | Fast, fully managed inference                                        | Isolated capacity and custom models                                                             |
| **Models**   | [Shared models](/docs/guide/supported-models#shared-endpoint-models) | [Dedicated models](/docs/guide/supported-models#dedicated-endpoint-models), plus custom weights |
| **Billing**  | Per token                                                            | Compute resources                                                                               |
| **Capacity** | Managed by Modal                                                     | Configurable autoscaling, including scale-to-zero                                               |

## Create an endpoint

Choose a model from [supported models](/docs/guide/supported-models), which
lists the serving modes each model supports. Both CLI examples below require a
[Proxy Token](#proxy-tokens).

The CLI creates Dedicated Endpoints by default:

```bash
modal endpoint create --model Qwen/Qwen3.5-4B
```

Pass `--shared` to create a Shared Endpoint:

```bash
modal endpoint create --shared --model moonshotai/Kimi-K3
```

The command prints the Endpoint ID and a dashboard link to follow provisioning.
You can also create an Endpoint from the
[**Endpoints**](https://modal.com/endpoints) tab in the dashboard. To learn more
about a model, browse the
[Model Library](https://modal.com/library).

## Proxy tokens

Shared Endpoints always require a
[Proxy Token](/docs/guide/webhook-proxy-auth). Dedicated Endpoints require one
by default. Create one with the CLI:

```bash
modal workspace proxy-tokens create
```

Join the token ID and secret with a period (`.`) and pass them as a bearer token:

```
Authorization: Bearer wk-<id>.ws-<secret>
```

The combined value can be used as the API key in an OpenAI-compatible client.
See [Proxy Tokens](/docs/guide/webhook-proxy-auth) for environment scoping and
other authentication options. Dedicated Endpoints can also be created with
`--unauthenticated`.

## Call an endpoint

Text-generation models on both Shared and Dedicated Endpoints can be called
through the OpenAI-compatible Chat Completions and Responses APIs or the
Anthropic-compatible Messages API. Embedding models can be called through the
OpenAI-compatible Embeddings API.

### Model names

Set `model` to the value shown in the dashboard's request examples.
You can also retrieve it through the OpenAI-compatible Models API:

```bash
curl "<your-endpoint-url>/v1/models" \
  -H "Authorization: Bearer $MODAL_PROXY_TOKEN_ID.$MODAL_PROXY_TOKEN_SECRET"
```

### Send a request

This example uses the Chat Completions API and a
[proxy token](#proxy-tokens):

```bash
curl "<your-endpoint-url>/v1/chat/completions" \
  -H "Authorization: Bearer $MODAL_PROXY_TOKEN_ID.$MODAL_PROXY_TOKEN_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "<model-name>",
    "messages": [{ "role": "user", "content": "Hello!" }]
  }'
```

See [Endpoint integrations](/docs/guide/endpoint-integrations) for connecting
coding agents like OpenCode, Codex, and Claude Code to a Shared Endpoint.

## Affinity routing

LLM serving engines cache the KV state of a prompt prefix, so a request that
reuses the prefix of an earlier request is fastest when it lands on the same
container. Multi-turn conversations and agent loops, where each request repeats
the previous turns, benefit the most.

To keep the requests of one conversation together, send the same routing key in
the `Modal-Routing-Affinity-Key` header on each of them. The routing key is an
arbitrary string; use one per conversation, task, or agent run.

```bash
curl "<your-endpoint-url>/v1/chat/completions" \
  -H "Authorization: Bearer $MODAL_PROXY_TOKEN_ID.$MODAL_PROXY_TOKEN_SECRET" \
  -H "Modal-Routing-Affinity-Key: $CUSTOM_CONVERSATION_ID" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "<model-name>",
    "messages": [{ "role": "user", "content": "Hello!" }]
  }'
```

Choose the routing key to match the shared prefix:

* **One key per conversation**, not per user or application. A single key
  shared by many unrelated conversations concentrates all of that traffic on one
  container.
* **Use a new key when the prefix changes**, for example after compacting or
  summarizing a long context. The cached prefix no longer applies, and a new key
  lets the request move to a container with free capacity.

Note that requests may be routed to a different container when the Endpoint
scales or a container is replaced or overloaded.
