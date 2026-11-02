# wsgi_app

```python
wsgi_app(*, label=None, custom_domains=None, requires_proxy_auth=False)
```
Decorator for registering a WSGI app with a Modal function.

Web Server Gateway Interface (WSGI) is a standard for synchronous Python web apps.
It has been [succeeded by the ASGI interface](https://asgi.readthedocs.io/en/latest/introduction.html#wsgi-compatibility)
which is compatible with ASGI and supports additional functionality such as web sockets.
Modal supports ASGI via [`asgi_app`](https://modal.com/docs/sdk/py/latest/asgi_app).

To learn how to use this decorator with popular web frameworks, see the
[guide on Web Functions](https://modal.com/docs/guide/webhooks).

**Usage**

```python
from typing import Callable

@app.function()
@modal.wsgi_app()
def create_wsgi() -> Callable:
    ...
```
