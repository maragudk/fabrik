# Proxy Tokens

Use Proxy Tokens to prevent unauthorized clients from reaching your [Endpoints](/docs/guide/endpoints), [Servers](/docs/guide/servers), and [Web Functions](/docs/guide/webhooks). Proxy Tokens can be created in the [Dashboard settings](/settings/proxy-auth-tokens) or with the [`modal workspace proxy-tokens`](/docs/cli/latest/workspace#modal-workspace-proxy-tokens) CLI.

## Authentication models

Endpoints and Servers require authentication by default. To accept public traffic instead, pass `--unauthenticated` to `modal endpoint create` or set `unauthenticated=True` in the [`@app.server()`](/docs/sdk/py/latest/App#server) decorator:

```python notest
@app.server()
class Private:
    ...


@app.server(unauthenticated=True)
class Public:
    ...
```

In contrast, Web Functions are **publicly available** by default. Enable authentication by setting `requires_proxy_auth=True` in the [`fastapi_endpoint`](/docs/sdk/py/latest/fastapi_endpoint), [`asgi_app`](/docs/sdk/py/latest/asgi_app), [`wsgi_app`](/docs/sdk/py/latest/wsgi_app), or [`web_server`](/docs/sdk/py/latest/web_server) decorators:

```python
@app.function()
@modal.fastapi_endpoint()
def public():
    return "hello world"


@app.function()
@modal.fastapi_endpoint(requires_proxy_auth=True)
def private():
    return "hello friend"
```

The `public` endpoint can be hit by any client over the Internet:

```bash
curl https://public-url--goes-here.modal.run
```

The `private` endpoint cannot:

```bash
curl --fail-with-body https://private-url--goes-here.modal.run
# modal-http: missing credentials for proxy authorization
# curl: (22) The requested URL returned error: 401
# https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/401
```

## Authenticating requests

A Proxy Token comprises a Token ID / Token Secret pair. Requests are authenticated by passing the pair in HTTP headers. They can be sent as separate `Modal-Key` and `Modal-Secret` headers:

```bash
export TOKEN_ID=wk-1234abcd
export TOKEN_SECRET=ws-1234abcd
curl -H "Modal-Key: $TOKEN_ID" \
     -H "Modal-Secret: $TOKEN_SECRET" \
     https://private-url--goes-here.modal.run
```

Alternatively, they can be joined with a period (`.`) and passed as a single `Authorization: Bearer` header:

```bash
export TOKEN_ID=wk-1234abcd
export TOKEN_SECRET=ws-1234abcd
curl -H "Authorization: Bearer $TOKEN_ID.$TOKEN_SECRET" \
     https://private-url--goes-here.modal.run
```

This is the same scheme the OpenAI API uses (`Authorization: Bearer <api-key>`), so the combined value can be used as the API key in any OpenAI-compatible client or gateway.

## Environment scoping

On Workspaces with RBAC enabled, tokens are scoped to specific Environments. See the [RBAC guide](/docs/guide/rbac#proxy-tokens) for more information.

## Blocking unauthenticated URLs

Workspace Managers can prevent deployments in an Environment from exposing unauthenticated URLs — Endpoints created with `--unauthenticated`, Servers with `unauthenticated=True`, and Web Functions without `requires_proxy_auth=True`.

The control lives in [Settings → Environments](/settings/workspace-management/environments):

* **Workspace defaults** sets a default that applies to every Environment unless the Environment overrides it.
* Each Environment can **Inherit** the workspace default, or explicitly **Block** or **Allow** unauthenticated URLs.

When blocking is in effect, `modal deploy`, `modal endpoint create`, or creating an Endpoint through the Dashboard fail if proxy auth is not required.
