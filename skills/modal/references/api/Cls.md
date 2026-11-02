# Cls


```python
class Cls(modal.object.Object)
```

Cls adds method pooling and [lifecycle hook](https://modal.com/docs/guide/lifecycle-functions) behavior
to [modal.Function](https://modal.com/docs/sdk/py/latest/Function).

Generally, you will not construct a Cls directly.
Instead, use the [`@app.cls()`](https://modal.com/docs/sdk/py/latest/App#cls) decorator on the App object.


## hydrate

```python
hydrate(self, client=None)
```
Synchronize the local object with its identity on the Modal server.

It is rarely necessary to call this method explicitly, as most operations
will lazily hydrate when needed. The main use case is when you need to
access object metadata, such as its ID.

*Added in v0.72.39*: This method replaces the deprecated `.resolve()` method.

## from_name

```python
from_name(cls, app_name, name, *, version=None, environment_name=None,
    client=None)
```
Reference a Cls from a deployed App by its name.

This is a lazy method that defers hydrating the local
object with metadata from Modal servers until the first
time it is actually used.

**Parameters**

<Parameter name="app_name" type="str" description="Name of the deployed App that defines this class." />
<Parameter name="name" type="str" description="Object tag of the Cls within that App." />
<Parameter name="environment_name" type="str | None" defaultValue="None" description="Workspace environment for the lookup; defaults to the active environment." />
<Parameter name="client" type="&quot;_Client | None&quot;" defaultValue="None" description="Optional Modal client; defaults to the process client." />

**Returns**

A ``Cls`` reference that hydrates on first use.

**Usage**

```python
Model = modal.Cls.from_name("other-app", "Model")
```

The `version` parameter constructs a version-pinned Cls:

```python
Modelv3 = modal.Cls.from_name("other-app", "Model", version=3)
```

## with_options

```python
with_options(self, *, cpu=None, memory=None, gpu=None, env=None, secrets=None,
    volumes={}, retries=None, max_containers=None, buffer_containers=None,
    scaledown_window=None, timeout=None, region=None, cloud=None,
    routing_region=None)
```
Override the static Cls configuration with invocation-specific values.

This method will return a new variant of the Cls that will autoscale independently of the
base configuration.

Note that options cannot be "unset" with this method (i.e., if a GPU is configured in the
`@app.cls()` decorator, passing `gpu=None` here will not create a CPU-only instance).

Container arguments (``volumes`` and ``secrets``) from later calls replace earlier values; they are not merged.

**Parameters**

<Parameter name="cpu" type="float | tuple[float, float] | None" defaultValue="None" description="CPU cores for instances created from this Cls (see ``@app.function`` / ``@app.cls`` resource options)." />
<Parameter name="memory" type="int | tuple[int, int] | None" defaultValue="None" description="Memory in MiB, or min/max pair, for those instances." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU type string, for example ``A100``." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables merged into a temporary secret for this configuration." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Additional secrets attached to the service function." />
<Parameter name="volumes" type="dict[str | PurePosixPath, _Volume | _CloudBucketMount]" defaultValue="&#123;&#125;" description="Volume and cloud-bucket mounts (paths to ``Volume`` or ``CloudBucketMount``)." />
<Parameter name="retries" type="int | Retries | None" defaultValue="None" description="Retry policy or count for invocations." />
<Parameter name="max_containers" type="int | None" defaultValue="None" description="Cap on concurrently running containers for this Cls configuration." />
<Parameter name="buffer_containers" type="int | None" defaultValue="None" description="Extra idle containers kept warm while the Function is active." />
<Parameter name="scaledown_window" type="int | None" defaultValue="None" description="Seconds a container may stay idle before scaling down." />
<Parameter name="timeout" type="int | None" defaultValue="None" description="Function timeout in seconds." />
<Parameter name="region" type="str | Sequence[str] | None" defaultValue="None" description="One region or a list of regions to schedule on." />
<Parameter name="cloud" type="str | None" defaultValue="None" description="Cloud provider (for example ``aws``, ``gcp``, ``oci``, or ``auto``)." />
<Parameter name="routing_region" type="str | None" defaultValue="None" description="Region that inputs and outputs are routed through for this Cls." />

**Returns**

A new ``Cls`` with the merged options.

**Usage**

You can use this method after looking up the Cls from a deployed App or if you have a
direct reference to a Cls from another Function or local entrypoint on its App:

```python notest
Model = modal.Cls.from_name("my_app", "Model")
ModelUsingGPU = Model.with_options(gpu="A100")
ModelUsingGPU().generate.remote(input_prompt)  # Run with an A100 GPU
```

The method can be called multiple times to "stack" updates:

```python notest
Model.with_options(gpu="A100").with_options(scaledown_window=300)  # Use an A100 with slow scaledown
```

## with_concurrency

```python
with_concurrency(self, *, max_inputs, target_inputs=None)
```
Override the static Cls configuration with invocation-specific input concurrency settings.

**Parameters**

<Parameter name="max_inputs" type="int" description="Maximum number of inputs processed concurrently per container." />
<Parameter name="target_inputs" type="int | None" defaultValue="None" description="Optional target concurrency; see ``@app.cls`` / Function concurrency docs." />

**Returns**

A new ``Cls`` with the merged concurrency settings.

**Usage**

```python notest
Model = modal.Cls.from_name("my_app", "Model")
ModelUsingGPU = Model.with_options(gpu="A100").with_concurrency(max_inputs=100)
ModelUsingGPU().generate.remote(42)  # will run on an A100 GPU with input concurrency enabled
```

## with_batching

```python
with_batching(self, *, max_batch_size, wait_ms)
```
Override the static Cls configuration with invocation-specific dynamic batching settings.

**Parameters**

<Parameter name="max_batch_size" type="int" description="Maximum batch size for dynamic batching." />
<Parameter name="wait_ms" type="int" description="Maximum time to wait to fill a batch, in milliseconds." />

**Returns**

A new ``Cls`` with the merged batching settings.

**Usage**

```python notest
Model = modal.Cls.from_name("my_app", "Model")
ModelUsingGPU = Model.with_options(gpu="A100").with_batching(max_batch_size=100, wait_ms=1000)
ModelUsingGPU().generate.remote(42)  # A100 with dynamic batching
```
