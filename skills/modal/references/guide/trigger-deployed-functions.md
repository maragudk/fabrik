# Invoking deployed Functions

Modal Functions in [deployed Apps](/docs/guide/managing-deployments) can be invoked
from outside of the App's source by performing a *Function lookup*:

<CodeTabs>
  {#snippet python()}

```python notest
f = modal.Function.from_name("my-app", "f")
result = f.remote()
```

{/snippet}

{#snippet python\_async()}

```python notest
f = modal.Function.from_name("my-app", "f")
result = await f.remote.aio()
```

{/snippet}

{#snippet javascript()}

```javascript notest
const f = await modal.functions.fromName("my-app", "f");
result = await f.remote();
```

{/snippet}

{#snippet go()}

```go notest
f, _ := mc.Functions.FromName(ctx, "my-app", "f", nil)
result, err := f.Remote(ctx, nil, nil)
```

{/snippet} </CodeTabs>

Function lookups are scoped by the name of the App, the Function's name within
that App, and optionally the [environment](/docs/guide/environments) the App is
deployed in. Note that lookups are supported only for *deployed* Apps. Looking up
a Function will fail if its App is [ephemeral](/docs/guide/apps#ephemeral-apps),
e.g. running via the `modal serve` CLI.

## Use cases

Function lookups are useful when you want to treat your Modal App as a remote
service.

For example, you may wish to organize your Modal codebase into multiple
loosely-coupled Apps with distinct deployment lifecycles. Lookups allow
Functions in these Apps to call each other as if they were members of the same
App.

You may also have a codebase outside of Modal that needs to execute certain
operations that would benefit from Modal's scalable compute. Modal Function
lookups turn that into a simple function call, automatically handling the
serialization and deserialization of arguments, results, and exceptions.
With Modal's [JS and Go SDKs](/docs/guide/sdk-javascript-go), the calling
codebase does not even need to be written in Python.

## Invocation patterns

Any remote invocation method can be used after looking up a Function handle.

For example, you can spawn a background execution and poll its status:

<CodeTabs>
  {#snippet python()}

```python notest
f = modal.Function.from_name("my-app", "f")
function_call = f.spawn(42)

# Poll for the result without blocking by passing timeout=0.
try:
    result = function_call.get(timeout=0)
except TimeoutError:
    result = None  # still running
```

{/snippet}

{#snippet python\_async()}

```python notest
f = modal.Function.from_name("my-app", "f")
function_call = await f.spawn.aio(42)

# Poll for the result without blocking by passing timeout=0.
try:
    result = await function_call.get.aio(timeout=0)
except TimeoutError:
    result = None  # still running
```

{/snippet}

{#snippet javascript()}

```javascript notest
const f = await modal.functions.fromName("my-app", "f");
const functionCall = await f.spawn([42]);

// Poll for the result without blocking by passing timeoutMs: 0.
let result;
try {
  result = await functionCall.get({ timeoutMs: 0 });
} catch (err) {
  if (!(err instanceof FunctionTimeoutError)) throw err;
  result = null; // still running
}
```

{/snippet}

{#snippet go()}

```go notest
f, _ := mc.Functions.FromName(ctx, "my-app", "f", nil)
functionCall, _ := f.Spawn(ctx, []any{42}, nil)

// Poll for the result without blocking by passing a zero *time.Duration timeout
zero := time.Duration(0)
result, err := functionCall.Get(ctx, &modal.FunctionCallGetParams{Timeout: &zero})
// A non-nil err indicates the call is still running.
```

{/snippet} </CodeTabs>

Or you can distribute embarrassingly parallel work across multiple containers:

<CodeTabs>
  {#snippet python()}

```python notest
f = modal.Function.from_name("my-app", "f")
results = list(f.map(range(5)))
```

{/snippet}

{#snippet python\_async()}

```python notest
f = modal.Function.from_name("my-app", "f")
results = [result async for result in f.map.aio(range(5))]
```

{/snippet} </CodeTabs>

Note: `Function.map()` is currently supported only in Python.

When your Function is defined as a Modal Cls, you can pass
[parameters](/docs/guide/parametrized-functions) and invoke
specific methods after a lookup:

<CodeTabs>
  {#snippet python()}

```python notest
Model = modal.Cls.from_name("my-app", "Model")
obj = Model(size="35B")
result = obj.generate.remote("hello")
```

{/snippet}

{#snippet python\_async()}

```python notest
Model = modal.Cls.from_name("my-app", "Model")
obj = Model(size="35B")
result = await obj.generate.remote.aio("hello")
```

{/snippet}

{#snippet javascript()}

```javascript notest
const cls = await modal.cls.fromName("my-app", "Model");
const obj = await cls.instance({ size: "35B" });
const generate = obj.method("generate");
const result = await generate.remote(["hello"]);
```

{/snippet}

{#snippet go()}

```go notest
cls, _ := mc.Cls.FromName(ctx, "my-app", "Model", nil)
obj, _ := cls.Instance(ctx, map[string]any{"size": "35B"})
generate, _ := obj.Method("generate")
result, _ := generate.Remote(ctx, []any{"hello"}, nil)
```

{/snippet} </CodeTabs>

It's also possible to
[dynamically configure](/docs/guide/dynamic-function-config) a Function
or Cls via a remote lookup. For example, you can select a GPU type that
aligns with the specific model you are invoking:

<CodeTabs>
  {#snippet python()}

```python notest
Model = modal.Cls.from_name("my-app", "Model")
obj = Model.with_options(gpu="H100")(size="35B")
result = obj.generate.remote("hello")
```

{/snippet}

{#snippet python\_async()}

```python notest
Model = modal.Cls.from_name("my-app", "Model")
obj = Model.with_options(gpu="H100")(size="35B")
result = await obj.generate.remote.aio("hello")
```

{/snippet}

{#snippet javascript()}

```javascript notest
const cls = await modal.cls.fromName("my-app", "Model");
const obj = await cls.withOptions({ gpu: "H100" }).instance({ size: "35B" });
const generate = obj.method("generate");
const result = await generate.remote(["hello"]);
```

{/snippet}

{#snippet go()}

```go notest
cls, _ := mc.Cls.FromName(ctx, "my-app", "Model", nil)
gpu := "H100"
obj, _ := cls.
	WithOptions(&modal.ClsWithOptionsParams{GPU: &gpu}).
	Instance(ctx, map[string]any{"size": "35B"})
generate, _ := obj.Method("generate")
result, _ := generate.Remote(ctx, []any{"hello"}, nil)
```

{/snippet} </CodeTabs>

## Version-pinned lookups

<Callout variant="gated-feature">

Version-pinned lookups are available on the <a href="/pricing">Team and Enterprise plans</a>.
Visit <a href="/settings/plans">workspace settings</a> to upgrade.

</Callout>

All Function invocations will route to the "latest" available version of the
App by default. During a
[rolling deployment](/docs/guide/managing-deployments#deployment-strategies),
this may correspond to an outdated version, but repeated invocation of the
Function handle will eventually reach the most recent deploy without any
need to refresh the handle.

It's also possible to look up a specific version of the App, which returns a
"version-pinned" Function handle:

<CodeTabs>
  {#snippet python()}

```python notest
f = modal.Function.from_name("my-app", "f", version=3)
result = f.remote()
```

{/snippet}

{#snippet python\_async()}

```python notest
f = modal.Function.from_name("my-app", "f", version=3)
result = await f.remote.aio()
```

{/snippet}

{#snippet javascript()}

```javascript notest
const f = await modal.functions.fromName("my-app", "f", { version: 3 });
result = await f.remote();
```

{/snippet}

{#snippet go()}

```go notest
f, _ := mc.Functions.FromName(ctx, "my-app", "f", &modal.FunctionFromNameParams{Version: 3})
result, err := f.Remote(ctx, nil, nil)
```

{/snippet} </CodeTabs>

If the version-pinned Function directly calls other Functions in the same App,
those calls will also be guaranteed to run on the same version (which is not
generally the case across deployments, even for calls within the same App).

Version-pinned invocations have a few tradeoffs. Principally, version-pinned
invocations will be handled by a distinct pool of containers with special rules
around autoscaling:

* Containers handling version-pinned invocations are not included in the
  Function's main `max_containers` budget. Instead, the limit will be applied at
  the level of *individual versions*. You must account for this if each container
  consumes a limited resource (e.g., a connection to a database).
* Version-pinned Functions will ignore the `min_containers` configuration in the
  Function decorator, and they will not maintain a warm pool by default. If this
  is desired, the `Function.autoscaler.update()` method can be used to
  dynamically configure a warm pool. It is the user's responsibility to scale the
  warm pool down after it is no longer needed.

Version pinning is supported only for App versions within your retention window
(i.e., versions that you could also roll back to). Longer retention windows are
available on the Enterprise plan.

## Authentication

Function lookups are authenticated via Modal [API tokens](/settings/tokens).
These tokens implicitly specify the Workspace targeted by the lookup.

Tokens are automatically read from the active profile in your `~/.modal.toml`
file. They can also be configured via the `MODAL_TOKEN_ID` and
`MODAL_TOKEN_SECRET` environment variables. These take precedence over the
`~/.modal.toml` when set.

## Limitations

While you can use any remote invocation method on a Function handle after a
lookup, `.local()` invocation is not supported, because the implementation
will not be available locally.

Unlike with remote calls between Functions in the same Python App, the
Function interfaces will not be legible to type checkers after a lookup.
Your code will have to explicitly narrow the result to treat it as a
concrete type.

## Invoking with HTTPS

Modal [Web Functions](/docs/guide/webhooks) can be invoked via HTTPS at a
[public URL](/docs/guide/webhook-urls).

Unlike Function lookups via one of our SDKs, Web Functions are not
authenticated by default, and authenticated Web Functions use
[Proxy Tokens](/docs/guide/webhook-proxy-auth) instead of Modal API tokens.

Web Functions can be invoked from web browsers, from Unix tools like
`curl`, or from any language with an HTTPS client.
