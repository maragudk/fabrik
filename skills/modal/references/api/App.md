# App


```python
class App(object)
```

A Modal App is a group of functions and classes that are deployed together.

The app serves at least three purposes:

* A unit of deployment for functions and classes.
* Syncing of identities of (primarily) functions and classes across processes
  (your local Python interpreter and every Modal container active in your application).
* Manage log collection for everything that happens inside your code.

**Registering functions with an app**

The most common way to explicitly register an Object with an app is through the
`@app.function()` decorator. It both registers the annotated function itself and
other passed objects, like schedules and secrets, with the app:

```python
import modal

app = modal.App()

@app.function(
    secrets=[modal.Secret.from_name("some_secret")],
    schedule=modal.Period(days=1),
)
def foo():
    pass
```

In this example, the secret and schedule are registered with the app.

```python
__init__(self, name=None, *, tags=None, image=None, secrets=[], volumes={},
    include_source=True)
```
Construct a new app, optionally with default image, mounts, secrets, or volumes.

**Parameters**

<Parameter name="name" type="str | None" defaultValue="None" description="Optional app name used for registration and lookup." />
<Parameter name="tags" type="dict[str, str] | None" defaultValue="None" description="Additional metadata to set on the App." />
<Parameter name="image" type="_Image | None" defaultValue="None" description="Default image for the App (otherwise defaults to `modal.Image.debian_slim()`)." />
<Parameter name="secrets" type="Sequence[_Secret]" defaultValue="[]" description="Secrets to add for all Functions in the App." />
<Parameter name="volumes" type="dict[str | PurePosixPath, _Volume]" defaultValue="&#123;&#125;" description="Volume mounts to use for all Functions." />
<Parameter name="include_source" type="bool" defaultValue="True" description="Default for whether Function source files are added to the Modal container (per-function override possible)." />

**Usage**

```python notest
image = modal.Image.debian_slim().pip_install(...)
secret = modal.Secret.from_name("my-secret")
volume = modal.Volume.from_name("my-data")
app = modal.App(image=image, secrets=[secret], volumes={"/mnt/data": volume})
```

## name

```python
name(self)
```
The user-provided name of the App.

**Returns**

The configured app name, if any.

## app_id

```python
app_id(self)
```
Return the app_id of a running or stopped app.

**Returns**

The app ID when the app has been deployed or run, otherwise None.

## description

```python
description(self)
```
The App's `name`, if available, or a fallback descriptive identifier.

**Returns**

Human-readable description string for the app.

## lookup

```python
lookup(name, *, client=None, environment_name=None, create_if_missing=False)
```
Look up an App with a given name, creating a new App if necessary.

Note that Apps created through this method will be in a deployed state,
but they will not have any associated Functions or Classes. This method
is mainly useful for creating an App to associate with a Sandbox.

**Parameters**

<Parameter name="name" type="str" description="App name to resolve or create." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use; defaults to `Client.from_env()` when omitted." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Optional environment name; defaults to the configured environment." />
<Parameter name="create_if_missing" type="bool" defaultValue="False" description="If True, create the app when it does not already exist." />

**Returns**

An `App` handle tied to the deployed app record.

**Usage**

```python
app = modal.App.lookup("my-app", create_if_missing=True)
modal.Sandbox.create("echo", "hi", app=app)
```

## get_dashboard_url

```python
get_dashboard_url(self)
```
Get the dashboard URL for the App.

**Returns**

The dashboard URL for the App.

**Usage**

```python
app = modal.App.lookup("my-app")
print(app.get_dashboard_url())
```

## run

```python
run(self, *, name=None, client=None, detach=False, interactive=False,
    environment_name=None)
```
Context manager that runs an ephemeral app on Modal.

Use this as the main entry point for your Modal application. All calls
to Modal Functions should be made within the scope of this context
manager, and they will correspond to the current App.

Note that you should not invoke this in global scope of a file where you have
Modal Functions or Classes defined, since that would run the block when the Function
or Cls is imported in your containers as well. If you want to run it as your entrypoint,
consider protecting it with ``if __name__ == "__main__"``.

**Parameters**

<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use for the run session." />
<Parameter name="detach" type="bool" defaultValue="False" description="Whether to detach after starting the app." />
<Parameter name="interactive" type="bool" defaultValue="False" description="Whether to run in interactive mode." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Optional environment name; defaults to the configured environment." />

**Returns**

Async context manager yielding this `App` while it is running.

**Usage**

```python notest
with app.run():
    some_modal_function.remote()
```

To enable output printing (i.e., to see App logs), use `modal.enable_output()`:

```python notest
with modal.enable_output():
    with app.run():
        some_modal_function.remote()
```

Note that you should not invoke this in global scope of a file where you have Modal
Functions or Classes defined, since that would run the block when the Function or Cls
is imported in your containers as well. If you want to run it as your entrypoint,
consider protecting it:

```python
if __name__ == "__main__":
    with app.run():
        some_modal_function.remote()
```

You can then run your script with:

```shell
python app_module.py
```

## deploy

```python
deploy(self, *, name=None, environment_name=None, tag="", client=None,
    strategy="rolling")
```
Deploy the App so that it is available persistently.

Deployed Apps will be available for lookup or web-based invocations until they are stopped.
Unlike with `App.run`, this method will return as soon as the deployment completes.

This method is a programmatic alternative to the `modal deploy` CLI command.

Unlike with `App.run`, Function logs will not stream back to the local client after the
App is deployed.

Note that you should not invoke this method in global scope, as that would redeploy
the App every time the file is imported. If you want to write a programmatic deployment
script, protect this call so that it only runs when the file is executed directly.

**Parameters**

<Parameter name="name" type="str | None" defaultValue="None" description="Name for the deployment, overriding any set on the App." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Environment to deploy the App in." />
<Parameter name="tag" type="str" defaultValue="&quot;&quot;" description="Optional metadata that is specific to this deployment." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Alternate client to use for communication with the server." />
<Parameter name="strategy" type="str" defaultValue="&quot;rolling&quot;" description="Deployment strategy. ``rolling`` (default) shifts traffic gradually to new containers while old ones drain. ``recreate`` terminates all running containers as part of the deployment before new work starts." />

**Returns**

This app instance after deployment completes.

**Usage**

```python notest
app = App("my-app")
app.deploy()
```

To enable output printing (i.e., to see build logs), use `modal.enable_output()`:

```python notest
app = App("my-app")
with modal.enable_output():
    app.deploy()
```

Unlike with `App.run`, Function logs will not stream back to the local client after the App is deployed.

Note that you should not invoke this method in global scope, as that would redeploy the App every time
the file is imported. If you want to write a programmatic deployment script, protect this call so that it
only runs when the file is executed directly. You can then run your script with:

```python notest
if __name__ == "__main__":
    with modal.enable_output():
        app.deploy()
```

Then you can deploy your app with:

```shell
python app_module.py
```

## local_entrypoint

```python
local_entrypoint(self, _warn_parentheses_missing=None, *, name=None)
```
Decorate a function to be used as a CLI entrypoint for a Modal App.

These functions can be used to define code that runs locally to set up the app,
and act as an entrypoint to start Modal functions from. Note that regular
Modal functions can also be used as CLI entrypoints, but unlike `local_entrypoint`,
those functions are executed remotely directly.

Note that an explicit [`app.run()`](https://modal.com/docs/sdk/py/latest/App#run) is not needed, as an
[app](https://modal.com/docs/guide/apps) is automatically created for you.

**Parameters**

<Parameter name="name" type="str | None" defaultValue="None" description="Optional name for the entrypoint; defaults to the function&#x27;s qualified name." />

**Returns**

A decorator that registers the wrapped callable as a local CLI entrypoint.

**Usage**

```python
@app.local_entrypoint()
def main():
    some_modal_function.remote()
```

You can call the function using `modal run` directly from the CLI:

```shell
modal run app_module.py
```

Note that an explicit `app.run()` is not needed, as an app is automatically created for you.

**Multiple entrypoints**

If you have multiple `local_entrypoint` functions, qualify the name:

```shell
modal run app_module.py::app.some_other_function
```

**Parsing arguments**

If your entrypoint function take arguments with primitive types, `modal run` automatically
parses them as CLI options. For example, the following function can be called with
`modal run app_module.py --foo 1 --bar "hello"`:

```python
@app.local_entrypoint()
def main(foo: int, bar: str):
    some_modal_function.call(foo, bar)
```

Currently, `str`, `int`, `float`, `bool`, and `datetime.datetime` are supported.
Use `modal run app_module.py --help` for more information on usage.

## function

```python
function(self, *, image=None, schedule=None, env=None, secrets=None, gpu=None,
    serialized=False, network_file_systems={}, volumes={}, cpu=None,
    memory=None, ephemeral_disk=None, min_containers=None, max_containers=None,
    buffer_containers=None, scaledown_window=None, proxy=None, retries=None,
    timeout=300, startup_timeout=None, name=None, is_generator=None, cloud=None,
    region=None, routing_region=None, nonpreemptible=False,
    enable_memory_snapshot=False, block_network=False,
    restrict_modal_access=False, single_use_containers=False, i6pn=None,
    include_source=None, experimental_options=None,
    _experimental_restrict_output=False, max_inputs=None)
```
Decorator to register a new Modal Function with this App.

**Parameters**

<Parameter name="image" type="_Image | None" defaultValue="None" description="The image to run as the container for the function." />
<Parameter name="schedule" type="Schedule | None" defaultValue="None" description="An optional Modal Schedule for the function." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables to set in the container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets to inject into the container as environment variables." />
<Parameter name="gpu" type="str | list[str] | None" defaultValue="None" description="GPU request; either a single GPU type or a list of types." />
<Parameter name="serialized" type="bool" defaultValue="False" description="Whether to send the function over using cloudpickle." />
<Parameter name="network_file_systems" type="dict[str | PurePosixPath, _NetworkFileSystem]" defaultValue="&#123;&#125;" description="Mountpoints for Modal NetworkFileSystems." />
<Parameter name="volumes" type="dict[str | PurePosixPath, _Volume | _CloudBucketMount]" defaultValue="&#123;&#125;" description="Mount points for Modal Volumes &amp; CloudBucketMounts." />
<Parameter name="cpu" type="float | tuple[float, float] | None" defaultValue="None" description="Specify, in fractional CPU cores, how many CPU cores to request. Or, pass (request, limit) to additionally specify a hard limit in fractional CPU cores. CPU throttling will prevent a container from exceeding its specified limit." />
<Parameter name="memory" type="int | tuple[int, int] | None" defaultValue="None" description="Specify, in MiB, a memory request which is the minimum memory required. Or, pass (request, limit) to additionally specify a hard limit in MiB." />
<Parameter name="ephemeral_disk" type="int | None" defaultValue="None" description="Specify, in MiB, the ephemeral disk size for the Function." />
<Parameter name="min_containers" type="int | None" defaultValue="None" description="Minimum number of containers to keep warm, even when Function is idle." />
<Parameter name="max_containers" type="int | None" defaultValue="None" description="Limit on the number of containers that can be concurrently running." />
<Parameter name="buffer_containers" type="int | None" defaultValue="None" description="Number of additional idle containers to maintain under active load." />
<Parameter name="scaledown_window" type="int | None" defaultValue="None" description="Max time (in seconds) a container can remain idle while scaling down." />
<Parameter name="proxy" type="_Proxy | None" defaultValue="None" description="Reference to a Modal Proxy to use in front of this function." />
<Parameter name="retries" type="int | Retries | None" defaultValue="None" description="Number of times to retry each input in case of failure." />
<Parameter name="timeout" type="int" defaultValue="300" description="Maximum execution time for inputs and startup time in seconds." />
<Parameter name="startup_timeout" type="int | None" defaultValue="None" description="Maximum startup time in seconds with higher precedence than `timeout`." />
<Parameter name="name" type="str | None" defaultValue="None" description="Sets the Modal name of the function within the app." />
<Parameter name="is_generator" type="None | bool" defaultValue="None" description="Set this to True if it&#x27;s a non-generator function returning a sync or async generator object." />
<Parameter name="cloud" type="str | None" defaultValue="None" description="Cloud provider to run the function on. Possible values are aws, gcp, oci, auto." />
<Parameter name="region" type="str | Sequence[str] | None" defaultValue="None" description="Region or regions to run the function on." />
<Parameter name="routing_region" type="str | None" defaultValue="None" description="Region to route inputs to the function through." />
<Parameter name="nonpreemptible" type="bool" defaultValue="False" description="Whether to run the function on a nonpreemptible instance." />
<Parameter name="enable_memory_snapshot" type="bool" defaultValue="False" description="Enable memory checkpointing for faster cold starts." />
<Parameter name="block_network" type="bool" defaultValue="False" description="Whether to block network access." />
<Parameter name="restrict_modal_access" type="bool" defaultValue="False" description="Whether to allow this function access to other Modal resources." />
<Parameter name="single_use_containers" type="bool" defaultValue="False" description="When True, containers will shut down after handling a single input." />
<Parameter name="i6pn" type="bool | None" defaultValue="None" description="Whether to enable IPv6 container networking within the region." />
<Parameter name="include_source" type="bool | None" defaultValue="None" description="Whether the file or directory containing the Function&#x27;s source should automatically be included in the container. When unset, falls back to the App-level configuration, or is otherwise True by default." />
<Parameter name="experimental_options" type="dict[str, Any] | None" defaultValue="None" description="Experimental options for the function." />
<Parameter name="_experimental_restrict_output" type="bool" defaultValue="False" description="Experimental; do not use pickle for return values." />
<Parameter name="max_inputs" type="int | None" defaultValue="None" description="Deprecated; replaced with `single_use_containers`." />

**Returns**

A decorator that registers the wrapped callable or partial as a Modal `Function`.

## cls

```python
cls(self, *, image=None, env=None, secrets=None, gpu=None, serialized=False,
    network_file_systems={}, volumes={}, cpu=None, memory=None,
    ephemeral_disk=None, min_containers=None, max_containers=None,
    buffer_containers=None, scaledown_window=None, proxy=None, retries=None,
    timeout=300, startup_timeout=None, cloud=None, region=None,
    routing_region=None, nonpreemptible=False, enable_memory_snapshot=False,
    block_network=False, restrict_modal_access=False,
    single_use_containers=False, i6pn=None, include_source=None,
    experimental_options=None, _experimental_restrict_output=False,
    max_inputs=None)
```
Decorator to register a new Modal [Cls](https://modal.com/docs/sdk/py/latest/Cls) with this App.

**Parameters**

<Parameter name="image" type="_Image | None" defaultValue="None" description="The image to run as the container for the class service." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables to set in the container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets to inject into the container as environment variables." />
<Parameter name="gpu" type="str | list[str] | None" defaultValue="None" description="GPU request; either a single GPU type or a list of types." />
<Parameter name="serialized" type="bool" defaultValue="False" description="Whether to send the class over using cloudpickle." />
<Parameter name="network_file_systems" type="dict[str | PurePosixPath, _NetworkFileSystem]" defaultValue="&#123;&#125;" description="Mountpoints for Modal NetworkFileSystems." />
<Parameter name="volumes" type="dict[str | PurePosixPath, _Volume | _CloudBucketMount]" defaultValue="&#123;&#125;" description="Mount points for Modal Volumes &amp; CloudBucketMounts." />
<Parameter name="cpu" type="float | tuple[float, float] | None" defaultValue="None" description="Specify, in fractional CPU cores, how many CPU cores to request. Or, pass (request, limit) to additionally specify a hard limit in fractional CPU cores. CPU throttling will prevent a container from exceeding its specified limit." />
<Parameter name="memory" type="int | tuple[int, int] | None" defaultValue="None" description="Specify, in MiB, a memory request which is the minimum memory required. Or, pass (request, limit) to additionally specify a hard limit in MiB." />
<Parameter name="ephemeral_disk" type="int | None" defaultValue="None" description="Specify, in MiB, the ephemeral disk size for the Function." />
<Parameter name="min_containers" type="int | None" defaultValue="None" description="Minimum number of containers to keep warm, even when Function is idle." />
<Parameter name="max_containers" type="int | None" defaultValue="None" description="Limit on the number of containers that can be concurrently running." />
<Parameter name="buffer_containers" type="int | None" defaultValue="None" description="Number of additional idle containers to maintain under active load." />
<Parameter name="scaledown_window" type="int | None" defaultValue="None" description="Max time (in seconds) a container can remain idle while scaling down." />
<Parameter name="proxy" type="_Proxy | None" defaultValue="None" description="Reference to a Modal Proxy to use in front of this function." />
<Parameter name="retries" type="int | Retries | None" defaultValue="None" description="Number of times to retry each input in case of failure." />
<Parameter name="timeout" type="int" defaultValue="300" description="Maximum execution time for inputs and startup time in seconds." />
<Parameter name="startup_timeout" type="int | None" defaultValue="None" description="Maximum startup time in seconds with higher precedence than `timeout`." />
<Parameter name="cloud" type="str | None" defaultValue="None" description="Cloud provider to run the function on. Possible values are aws, gcp, oci, auto." />
<Parameter name="region" type="str | Sequence[str] | None" defaultValue="None" description="Region or regions to run the function on." />
<Parameter name="routing_region" type="str | None" defaultValue="None" description="Region to route inputs to the function through." />
<Parameter name="nonpreemptible" type="bool" defaultValue="False" description="Whether to run the function on a non-preemptible instance." />
<Parameter name="enable_memory_snapshot" type="bool" defaultValue="False" description="Enable memory checkpointing for faster cold starts." />
<Parameter name="block_network" type="bool" defaultValue="False" description="Whether to block network access." />
<Parameter name="restrict_modal_access" type="bool" defaultValue="False" description="Whether to allow this class access to other Modal resources." />
<Parameter name="single_use_containers" type="bool" defaultValue="False" description="When True, containers will shut down after handling a single input." />
<Parameter name="i6pn" type="bool | None" defaultValue="None" description="Whether to enable IPv6 container networking within the region." />
<Parameter name="include_source" type="bool | None" defaultValue="None" description="When ``False``, don&#x27;t automatically add the App source to the container." />
<Parameter name="experimental_options" type="dict[str, Any] | None" defaultValue="None" description="Experimental options for the class service." />
<Parameter name="_experimental_restrict_output" type="bool" defaultValue="False" description="Experimental; do not use pickle for return values." />
<Parameter name="max_inputs" type="int | None" defaultValue="None" description="Deprecated; replaced with `single_use_containers`." />

**Returns**

A decorator that registers the wrapped class or partial as a Modal `Cls`.

## server

```python
server(self, *, image=None, env=None, secrets=None, gpu=None, serialized=False,
    volumes={}, cpu=None, memory=None, ephemeral_disk=None,
    target_concurrency=None, min_containers=None, max_containers=None,
    buffer_containers=None, scaleup_window=None, scaledown_window=None,
    startup_timeout=30, name=None, port=8000, unauthenticated=False,
    h2_enabled=False, exit_grace_period=0, routing_region="us-east",
    compute_region=None, cloud=None, nonpreemptible=False, proxy=None,
    i6pn=None, enable_memory_snapshot=False, include_source=None,
    experimental_options=None)
```
Decorator to register a new Modal Server with this App.

Servers run HTTP servers that are started in a `@modal.enter()` method.
Unlike `@app.cls()`, servers only expose HTTP endpoints and do not
support `.remote()` method calls.

See the [guide](https://modal.com/docs/guide/servers) for more information.

**Parameters**

<Parameter name="image" type="_Image | None" defaultValue="None" description="The image to run as the container for the server." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables to set in the container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets to inject into the container as environment variables." />
<Parameter name="gpu" type="str | list[str] | None" defaultValue="None" description="GPU request; either a single GPU type or a list of types." />
<Parameter name="serialized" type="bool" defaultValue="False" description="Whether to send the server class over using cloudpickle." />
<Parameter name="volumes" type="dict[
        str | PurePosixPath, _Volume | _CloudBucketMount
    ]" defaultValue="&#123;&#125;" description="Mount points for Modal Volumes &amp; CloudBucketMounts." />
<Parameter name="cpu" type="float | tuple[float, float] | None" defaultValue="None" description="Specify, in fractional CPU cores, how many CPU cores to request. Or, pass (request, limit) to additionally specify a hard limit in fractional CPU cores. CPU throttling will prevent a container from exceeding its specified limit." />
<Parameter name="memory" type="int | tuple[int, int] | None" defaultValue="None" description="Specify, in MiB, a memory request which is the minimum memory required. Or, pass (request, limit) to additionally specify a hard limit in MiB." />
<Parameter name="ephemeral_disk" type="int | None" defaultValue="None" description="Specify, in MiB, the ephemeral disk size for the server." />
<Parameter name="target_concurrency" type="float | None" defaultValue="None" description="Target number of concurrent requests per container; 0 disables autoscaling. May be fractional, e.g. 1.5 to target three concurrent requests per two containers." />
<Parameter name="min_containers" type="int | None" defaultValue="None" description="Minimum number of containers to keep running regardless of demand." />
<Parameter name="max_containers" type="int | None" defaultValue="None" description="Limit on the number of containers that can be concurrently running." />
<Parameter name="buffer_containers" type="int | None" defaultValue="None" description="Extra containers to scale up beyond current demand." />
<Parameter name="scaleup_window" type="int | None" defaultValue="None" description="Seconds of sustained demand required before scaling up new containers." />
<Parameter name="scaledown_window" type="int | None" defaultValue="None" description="Maximum duration (in seconds) idle containers wait before scaling down." />
<Parameter name="startup_timeout" type="int" defaultValue="30" description="Maximum container startup time in seconds." />
<Parameter name="name" type="str | None" defaultValue="None" description="Sets the Modal name of the function within the app, defaults to class name." />
<Parameter name="port" type="int" defaultValue="8000" description="Port the HTTP server listens on." />
<Parameter name="unauthenticated" type="bool" defaultValue="False" description="Whether the endpoint requires proxy authentication; required by default." />
<Parameter name="h2_enabled" type="bool" defaultValue="False" description="Enable HTTP/2." />
<Parameter name="exit_grace_period" type="int" defaultValue="0" description="Grace period for in-flight requests on shutdown." />
<Parameter name="routing_region" type="str" defaultValue="&quot;us-east&quot;" description="Region to route Server requests through." />
<Parameter name="compute_region" type="str | Sequence[str] | None" defaultValue="None" description="Region(s) where containers can be scheduled." />
<Parameter name="cloud" type="str | None" defaultValue="None" description="Cloud provider (aws, gcp, oci, auto)." />
<Parameter name="nonpreemptible" type="bool" defaultValue="False" description="Whether to use non-preemptible instances." />
<Parameter name="proxy" type="_Proxy | None" defaultValue="None" description="Modal Proxy to use in front of this server." />
<Parameter name="i6pn" type="bool | None" defaultValue="None" description="Enable IPv6 container networking." />
<Parameter name="enable_memory_snapshot" type="bool" defaultValue="False" description="Enable memory checkpointing." />
<Parameter name="include_source" type="bool | None" defaultValue="None" description="Whether to add source to container." />
<Parameter name="experimental_options" type="dict[str, Any] | None" defaultValue="None" description="Experimental options." />

**Usage**

```python
@app.server(port=8000, routing_region="us-east")
class MyServer:
    @modal.enter()
    def start(self):
        self.proc = subprocess.Popen(["python3", "-m", "http.server", "8000"])

    @modal.exit()
    def stop(self):
        self.proc.terminate()
```

## include

```python
include(self, /, other_app, inherit_tags=True)
```
Include another App's objects in this one.

Useful for splitting up Modal Apps across different self-contained files.

When `inherit_tags=True` any tags set on the other App will be inherited by this App
(with this App's tags taking precedence in the case of conflicts).

**Parameters**

<Parameter name="other_app" type="&quot;_App&quot;" description="App whose registered functions and classes are merged into this app." />
<Parameter name="inherit_tags" type="bool" defaultValue="True" description="If True, merge tags from `other_app` into this app (this app wins on conflicts)." />

**Returns**

This app instance for chaining.

**Usage**

```python
app_a = modal.App("a")
@app_a.function()
def foo():
    ...

app_b = modal.App("b")
@app_b.function()
def bar():
    ...

app_a.include(app_b)

@app_a.local_entrypoint()
def main():
    # use function declared on the included app
    bar.remote()
```

## set_tags

```python
set_tags(self, tags, *, client=None)
```
Attach key-value metadata to the App.

Tag metadata can be used to add organization-specific context to the App and can be
included in billing reports and other informational APIs. Tags can also be set in
the App constructor.

Any tags set on the App before calling this method will be removed if they are not
included in the argument (i.e., this method does not have `.update()` semantics).

**Parameters**

<Parameter name="tags" type="Mapping[str, str]" description="Complete tag set to store on the app (replaces previous tags)." />
<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use for the RPC." />

## get_tags

```python
get_tags(self, *, client=None)
```
Get the tags that are currently attached to the App.

**Parameters**

<Parameter name="client" type="_Client | None" defaultValue="None" description="Modal client to use for the RPC." />

**Returns**

Tags as a map from key to value.

## logs


```python
logs: AppLogsManager
```

Access logs for an `App`.

Use [`fetch()`](#logsfetch)
to read logs from a UTC time range, [`tail()`](#logstail)
to read the most recent logs, and [`stream()`](#logsstream)
to follow new logs as they arrive.

**See Also**

- [`modal app logs`](https://modal.com/docs/cli/latest/app#modal-app-logs):
    CLI access to logs for an App.


### logs.fetch

```python
fetch(self, *, since, until=None, source=None, search_text="")
```
Fetch App logs corresponding to the date range and filters.

**Parameters**

<Parameter name="since" type="datetime" description="Start date to fetch logs from. Must be in UTC or timezone-naive, which is interpreted as local time." />
<Parameter name="until" type="datetime | None" defaultValue="None" description="Defaults to current date if None. Must be in UTC or timezone-naive, which is interpreted as local time." />
<Parameter name="source" type="LogSource | None" defaultValue="None" description="Filter by source: &#x27;stdout&#x27;, &#x27;stderr&#x27;, or &#x27;system&#x27;." />
<Parameter name="search_text" type="str" defaultValue="&quot;&quot;" description="Filter by search text." />

**Yields**

`LogEntry` objects in chronological order.

**Usage**

```python notest
app = modal.App.lookup("my-app")

for entry in app.logs.fetch(
    since=datetime.now() - timedelta(hours=4),
    source="stdout",
):
    print(entry.message, end="")
```

### logs.tail

```python
tail(self, entries=100, *, source=None)
```
Fetch the most recent App logs.

**Parameters**

<Parameter name="entries" type="int" defaultValue="100" description="The number of log entries to return." />
<Parameter name="source" type="LogSource | None" defaultValue="None" description="Filter by source: &#x27;stdout&#x27;, &#x27;stderr&#x27;, or &#x27;system&#x27;." />

**Yields**

`LogEntry` objects in chronological order.

**Usage**

```python notest
app = modal.App.lookup("my-app")

for entry in app.logs.tail(20):
    print(entry.message, end="")
```

### logs.stream

```python
stream(self, timeout=None)
```
Stream new App logs until the timeout is reached.

**Parameters**

<Parameter name="timeout" type="float | None" defaultValue="None" description="Number of seconds to wait between log entries before terminating the stream. By default, this will block until it is interrupted." />

**Yields**

`LogEntry` objects as they arrive.

**Usage**

```python notest
app = modal.App.lookup("my-app")

for entry in app.logs.stream(timeout=60):
    print(entry.message, end="")
```
