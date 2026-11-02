# Endpoint integrations

Connect OpenCode, Codex, or Claude Code to your
[Shared Endpoints](/docs/guide/shared-endpoints) through
`https://inference.us-west.modal.direct`. Set the request's `model` to the
Endpoint's hostname, for example `my-endpoint.us-west.modal.direct`.

To see which Shared Endpoints a token can reach, list all model IDs with:

```bash
curl "https://inference.us-west.modal.direct/v1/models" \
  -H "Authorization: Bearer $MODAL_PROXY_TOKEN_ID.$MODAL_PROXY_TOKEN_SECRET"
```

## OpenCode

[Install OpenCode](https://opencode.ai/docs/) and create a
[proxy token](/docs/guide/endpoints#proxy-tokens). In the OpenCode CLI, run
`/connect`, select Modal as the
[provider](https://opencode.ai/docs/providers/), and enter the token as the
API key in its combined form, `wk-<id>.ws-<secret>`. Then run `/models` and
select your endpoint by hostname.

For CI or other headless use, set the token in the environment instead of
running `/connect`:

```bash
export MODAL_PROXY_TOKEN="wk-<id>.ws-<secret>"
```

## Codex

[Install Codex](https://learn.chatgpt.com/docs/codex/cli), create a
[proxy token](/docs/guide/endpoints#proxy-tokens), and define Modal as a model
provider in `~/.codex/config.toml`:

```toml
# ~/.codex/config.toml
[model_providers.modal]
name = "Modal"
base_url = "https://inference.us-west.modal.direct/v1"
env_key = "MODAL_PROXY_TOKEN"
wire_api = "responses"
```

Then you can run Codex via the following command with the endpoint hostname as
the model ID:

```bash
export MODAL_PROXY_TOKEN="$MODAL_PROXY_TOKEN_ID.$MODAL_PROXY_TOKEN_SECRET"
codex \
  --model my-endpoint.us-west.modal.direct \
  --config model_provider='"modal"'
```

## Claude Code

[Install Claude Code](https://code.claude.com/docs/en/quickstart) and create a
[Proxy Token](/docs/guide/endpoints#proxy-tokens). Set the token in its combined
form, `wk-<id>.ws-<secret>`, and replace `my-endpoint.us-west.modal.direct` with
the hostname of an Endpoint whose model supports tool calling:

```bash
export ANTHROPIC_BASE_URL="https://inference.us-west.modal.direct"
export ANTHROPIC_AUTH_TOKEN="wk-<id>.ws-<secret>"
export ANTHROPIC_MODEL="my-endpoint.us-west.modal.direct"
export ANTHROPIC_DEFAULT_FABLE_MODEL="$ANTHROPIC_MODEL"
export ANTHROPIC_DEFAULT_OPUS_MODEL="$ANTHROPIC_MODEL"
export ANTHROPIC_DEFAULT_SONNET_MODEL="$ANTHROPIC_MODEL"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="$ANTHROPIC_MODEL"
claude
```
