# fastapi_endpoint

```python
fastapi_endpoint(*, method="GET", label=None, custom_domains=None, docs=False,
    requires_proxy_auth=False)
```
Create a Web Function that can be addressed via HTTP at a public URL.

Modal will internally use [FastAPI](https://fastapi.tiangolo.com/) to expose a
simple, single request handler. If you are defining your own `FastAPI` application
(e.g. if you want to define multiple routes), use `@modal.asgi_app` instead.

The Web Function created with this decorator will automatically have
[CORS](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS) enabled
and can leverage many of FastAPI's features.

For more information on using Modal with popular web frameworks, see our
[guide on Web Functions](https://modal.com/docs/guide/webhooks).

*Added in v0.73.82*: This function replaces the deprecated `@web_endpoint` decorator.
