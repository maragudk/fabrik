# web_server

```python
web_server(port, *, startup_timeout=5.0, label=None, custom_domains=None,
    requires_proxy_auth=False)
```
Decorator that registers an HTTP web server inside the container.

This is similar to `@modal.asgi_app` and `@modal.wsgi_app`, but it allows you to expose a full
HTTP server listening on a container port. This is useful for servers written in other languages
like Rust, as well as integrating with non-ASGI frameworks like aiohttp and Tornado.

The above example starts a simple file server, displaying the contents of the root directory.
Here, requests to the URL will go to external port 8000 on the container. The
`http.server` module is included with Python, but you could run anything here.

Internally, the web server is transparently converted into a Web Function by Modal, so it has
the same serverless autoscaling behavior as other Web Functions.

For more info, see the [guide on Web Functions](https://modal.com/docs/guide/webhooks).

**Usage**

```python
import subprocess

@app.function()
@modal.web_server(8000)
def my_file_server():
    subprocess.Popen("python -m http.server -d / 8000", shell=True)
```
