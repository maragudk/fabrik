# Named images

Named Images let you publish a Modal Image under a name that you can reference
later to use the Image, akin to a container registry.

This can be useful for stricter Image change management and for avoiding
unintended Image invalidation and rebuilds on latency-sensitive code paths.

Unlike inline Image definitions, referencing an image by name will never
implicitly rebuild an Image. The Image reference for a name is mutable,
and because the reference is typically updated only after a successful
publish, callers keep using the previous working Image while the new build is running.

A typical workflow using named images would be:

1. Define, build, and publish the Image in an independently run Image build script
2. Reference the published Image by name in Sandbox or Function code, getting the latest build of that image at the time

## Publishing an Image from a script

Use [`Image.build`](/docs/sdk/py/latest/Image#build) to build the
Image, then call `.publish()` on the resulting Image:

<CodeTabs>
  {#snippet python()}

```python notest
# build_image.py
app = modal.App.lookup("image-builds", create_if_missing=True)

image = (
    modal.Image.debian_slim(python_version="3.12")
    .apt_install("git")
    .uv_pip_install("numpy", "pandas", "scikit-learn")
    .run_commands("python -c 'import sklearn; print(sklearn.__version__)'")
)

with modal.enable_output():
    image.build(app).publish("analytics-runtime")
```

{/snippet}

{#snippet javascript()}

```javascript
// build_image.ts
const app = await modal.apps.fromName("image-builds", {
  createIfMissing: true,
});

const image = modal.images
  .fromRegistry("python:3.12-slim")
  .dockerfileCommands([
    "RUN apt-get update && apt-get install -y git",
    "RUN pip install numpy pandas scikit-learn",
    "RUN python -c 'import sklearn; print(sklearn.__version__)'",
  ]);

const builtImage = await image.build(app);
await builtImage.publish("analytics-runtime");
```

{/snippet}

{#snippet go()}

```go
// build_image.go
app, err := mc.Apps.FromName(ctx, "image-builds", &modal.AppFromNameParams{
	CreateIfMissing: true,
})

image := mc.Images.FromRegistry("python:3.12-slim", nil).
	DockerfileCommands([]string{
		"RUN apt-get update && apt-get install -y git",
		"RUN pip install numpy pandas scikit-learn",
		"RUN python -c 'import sklearn; print(sklearn.__version__)'",
	}, nil)

builtImage, err := image.Build(ctx, app, nil)
err = builtImage.Publish(ctx, "analytics-runtime", nil)
```

{/snippet} </CodeTabs>

## Starting Sandboxes using named Images

Named Images are especially useful for Sandboxes because Sandbox creation often happens
on a latency-sensitive path and you typically never want to block Sandbox creation on
rebuilding an Image.

Use [`Image.from_name`](/docs/sdk/py/latest/Image#from_name) when referencing
a named Image that you have previously built, and start the Sandbox using that:

<CodeTabs>
  {#snippet python()}

```python notest
# sandbox_launcher.py
sb = modal.Sandbox.create(
    "python",
    "-c",
    "import pandas, sklearn; print('ready')",
    # prefer named Images in Sandboxes to ensure they are never built during Sandbox launch
    image=modal.Image.from_name("analytics-runtime"),
    app=app,
)
print(sb.stdout.read())
```

{/snippet}

{#snippet javascript()}

```javascript
// sandbox_launcher.ts
// prefer named Images in Sandboxes to ensure they are never built during Sandbox launch
const image = await modal.images.fromName("analytics-runtime");
const sb = await modal.sandboxes.create(app, image);

const p = await sb.exec([
  "python",
  "-c",
  "import pandas, sklearn; print('ready')",
]);
console.log(await p.stdout.readText());
```

{/snippet}

{#snippet go()}

```go
// sandbox_launcher.go
// prefer named Images in Sandboxes to ensure they are never built during Sandbox launch
image, err := mc.Images.FromName(ctx, "analytics-runtime", nil)
sb, err := mc.Sandboxes.Create(ctx, app, image, nil)

p, err := sb.Exec(ctx, []string{
	"python",
	"-c",
	"import pandas, sklearn; print('ready')",
}, nil)
stdout, err := io.ReadAll(p.Stdout)
fmt.Println(string(stdout))
```

{/snippet} </CodeTabs>

## Running Functions using named Images

Named Images can also be used when defining Modal Functions when you want more control over when
a Function starts using a new Image. To use a named Image, point the Function image attribute
to a [`Image.from_name`](/docs/sdk/py/latest/Image#from_name) reference:

```python notest
# app.py
@app.function(image=modal.Image.from_name("analytics-runtime"))
def train():
    import pandas as pd
    from sklearn.linear_model import LinearRegression
    ...
```

Note that publishing a new version of this named Image would not automatically
update your deployed Functions to use the updated Image. You still need to redeploy
the App that references that name for the change to propagate.

## Tags

Every named Image is represented using a `{name}:{tag}` name - if you do not specify the tag part, the `:latest` tag is automatically used.
You can publish the same Image using multiple names or tag which can be useful to do things like versioning of images.
