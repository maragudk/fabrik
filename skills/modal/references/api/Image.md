# Image


```python
class Image(modal.object.Object)
```

Base class for container images to run functions in.

Do not construct this class directly; instead use one of its static factory methods,
such as `modal.Image.debian_slim`, `modal.Image.from_registry`, or `modal.Image.micromamba`.


## add_local_file

```python
add_local_file(self, local_path, remote_path, *, copy=False)
```
Adds a local file to the image at `remote_path` within the container.

By default (`copy=False`), the files are added to containers on startup and are not built into the actual Image,
which speeds up deployment.

Set `copy=True` to copy the files into an Image layer at build time instead, similar to how
[`COPY`](https://docs.docker.com/engine/reference/builder/#copy) works in a `Dockerfile`.

copy=True can slow down iteration since it requires a rebuild of the Image and any subsequent
build steps whenever the included files change, but it is required if you want to run additional
build steps after this one.

*Added in v0.66.40*: This method replaces the deprecated `modal.Image.copy_local_file` method.

**Parameters**

<Parameter name="local_path" type="str | Path" description="Path to the file on the local machine." />
<Parameter name="remote_path" type="str" description="Absolute path inside the container where the file should appear." />
<Parameter name="copy" type="bool" defaultValue="False" description="If True, bake the file into an image layer at build time; if False, mount at container startup." />

**Returns**

A new `Image` with the file layer or mount applied.

## add_local_dir

```python
add_local_dir(self, local_path, remote_path, *, copy=False, ignore=[])
```
Adds a local directory's content to the image at `remote_path` within the container.

By default (`copy=False`), the files are added to containers on startup and are not built into the actual Image,
which speeds up deployment.

Set `copy=True` to copy the files into an Image layer at build time instead, similar to how
[`COPY`](https://docs.docker.com/engine/reference/builder/#copy) works in a `Dockerfile`.

copy=True can slow down iteration since it requires a rebuild of the Image and any subsequent
build steps whenever the included files change, but it is required if you want to run additional
build steps after this one.

*Added in v0.66.40*: This method replaces the deprecated `modal.Image.copy_local_dir` method.

**Parameters**

<Parameter name="local_path" type="str | Path" description="Path to the directory on the local machine." />
<Parameter name="remote_path" type="str" description="Absolute path inside the container where the directory contents should appear." />
<Parameter name="copy" type="bool" defaultValue="False" description="If True, bake the tree into an image layer at build time; if False, mount at container startup." />
<Parameter name="ignore" type="Sequence[str] | Callable[[Path], bool]" defaultValue="[]" description="Predicate or pattern list for file exclusion (True means exclude). A sequence is converted to a dockerignore-style matcher." />

**Returns**

A new `Image` with the directory layer or mount applied.

**Usage**

```python
from modal import FilePatternMatcher

image = modal.Image.debian_slim().add_local_dir(
    "~/assets",
    remote_path="/assets",
    ignore=["*.venv"],
)

image = modal.Image.debian_slim().add_local_dir(
    "~/assets",
    remote_path="/assets",
    ignore=lambda p: p.is_relative_to(".venv"),
)

image = modal.Image.debian_slim().add_local_dir(
    "~/assets",
    remote_path="/assets",
    ignore=FilePatternMatcher("**/*.txt"),
)

# When including files is simpler than excluding them, you can use the `~` operator to invert the matcher.
image = modal.Image.debian_slim().add_local_dir(
    "~/assets",
    remote_path="/assets",
    ignore=~FilePatternMatcher("**/*.py"),
)

# You can also read ignore patterns from a file.
image = modal.Image.debian_slim().add_local_dir(
    "~/assets",
    remote_path="/assets",
    ignore=FilePatternMatcher.from_file("/path/to/ignorefile"),
)
```

## add_local_python_source

```python
add_local_python_source(self, *modules, copy=False, ignore=NON_PYTHON_FILES)
```
Adds locally available Python packages/modules to containers.

Adds all files from the specified Python package or module to containers running the Image.

Packages are added to the `/root` directory of containers, which is on the `PYTHONPATH`
of any executed Modal Functions, enabling import of the module by that name.

By default (`copy=False`), the files are added to containers on startup and are not built into the actual Image,
which speeds up deployment.

Set `copy=True` to copy the files into an Image layer at build time instead. This can slow down iteration since
it requires a rebuild of the Image and any subsequent build steps whenever the included files change, but it is
required if you want to run additional build steps after this one.

**Note:** This excludes all dot-prefixed subdirectories or files and all `.pyc`/`__pycache__` files.
To add full directories with finer control, use `.add_local_dir()` instead and specify `/root` as
the destination directory.

By default only includes `.py`-files in the source modules. Set the `ignore` argument to a list of patterns
or a callable to override this behavior.

*Added in v0.67.28*: This method replaces the deprecated `modal.Mount.from_local_python_packages` pattern.

**Parameters**

<Parameter name="*modules" type="str" description="Python package or module names to include from the local project." />
<Parameter name="copy" type="bool" defaultValue="False" description="If True, bake sources into an image layer; if False, mount at container startup." />
<Parameter name="ignore" type="Sequence[str] | Callable[[Path], bool]" defaultValue="NON_PYTHON_FILES" description="Patterns or callable controlling which files to exclude." />

**Returns**

A new `Image` with the Python source mount or layer applied.

**Usage**

```py
# includes everything except data.json
modal.Image.debian_slim().add_local_python_source("mymodule", ignore=["data.json"])

# exclude large files
modal.Image.debian_slim().add_local_python_source(
    "mymodule",
    ignore=lambda p: p.stat().st_size > 1e9
)
```

## from_id

```python
from_id(cls, image_id, client=None)
```
Construct an Image from an id and look up the Image result.

The ID of an Image object can be accessed using `.object_id`.

**Parameters**

<Parameter name="image_id" type="str" description="Image object ID to load." />
<Parameter name="client" type="&quot;modal.client.Client | None&quot;" defaultValue="None" description="Optional Modal client; uses the default synchronizer client when omitted." />

**Returns**

A hydrated `Image` handle for the given ID.

## build

```python
build(self, app)
```
Eagerly build an image.

If your image was previously built, then this method will not rebuild your image
and your cached image is returned.

For defining Modal functions, images are built automatically when deploying or running an App.
You do not need to build the image explicitly in that case.

**Parameters**

<Parameter name="app" type="modal.app._App" description="Initialized app used as the load context for the image build." />

**Returns**

This image after the build (and resolver load) completes.

**Usage**

```python
image = modal.Image.debian_slim().uv_pip_install("scipy", "numpy")

app = modal.App.lookup("build-image", create_if_missing=True)
with modal.enable_output():  # To see logs in your local terminal
    image.build(app)

# Save the image id
my_image_id = image.object_id

# Reference the image with the id or uses it another context.
built_image = modal.Image.from_id(my_image_id)
```

Alternatively, you can pre-build an image and use it in a sandbox:

```python notest
app = modal.App.lookup("sandbox-example", create_if_missing=True)

with modal.enable_output():
    image = modal.Image.debian_slim().uv_pip_install("scipy")
    image.build(app)

sb = modal.Sandbox.create("python", "-c", "import scipy; print(scipy)", app=app, image=image)
print(sb.stdout.read())
sb.terminate()
```

```python notest
app = modal.App()
image = modal.Image.debian_slim()

# No need to explicitly build the image for defining a function.
@app.function(image=image)
def f():
    ...
```

## pip_install

```python
pip_install(self, *packages, find_links=None, index_url=None,
    extra_index_url=None, pre=False, extra_options="", force_build=False,
    env=None, secrets=None, gpu=None)
```
Install a list of Python packages using pip.

**Parameters**

<Parameter name="*packages" type="str | list[str]" description="Python packages to install, e.g. ``numpy`` or ``matplotlib&gt;=3.5.0``." />
<Parameter name="find_links" type="str | None" defaultValue="None" description="Passed as ``--find-links`` to pip." />
<Parameter name="index_url" type="str | None" defaultValue="None" description="Passed as ``--index-url`` to pip." />
<Parameter name="extra_index_url" type="str | None" defaultValue="None" description="Passed as ``--extra-index-url`` to pip." />
<Parameter name="pre" type="bool" defaultValue="False" description="If True, allow pre-release versions (``--pre``)." />
<Parameter name="extra_options" type="str" defaultValue="&quot;&quot;" description="Additional raw options for pip, e.g. ``--no-build-isolation``." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds (similar to ``docker build --no-cache``)." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables set in the build container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets injected as environment variables during the build." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU type to attach to the builder container." />

**Returns**

A new `Image` with the pip install layer applied.

**Usage**

Simple installation:

```python
image = modal.Image.debian_slim().pip_install("click", "httpx~=0.23.3")
```

More complex installation:

```python
image = (
    modal.Image.from_registry(
        "nvidia/cuda:12.2.0-devel-ubuntu22.04", add_python="3.11"
    )
    .pip_install(
        "ninja",
        "packaging",
        "wheel",
        "transformers==4.40.2",
    )
    .pip_install(
        "flash-attn==2.5.8", extra_options="--no-build-isolation"
    )
)
```

## pip_install_private_repos

```python
pip_install_private_repos(self, *repositories, git_user, find_links=None,
    index_url=None, extra_index_url=None, pre=False, extra_options="", gpu=None,
    env=None, secrets=None, force_build=False)
```
Install a list of Python packages from private git repositories using pip.

This method currently supports Github and Gitlab only.

- **Github:** Provide a `modal.Secret` that contains a `GITHUB_TOKEN` key-value pair
- **Gitlab:** Provide a `modal.Secret` that contains a `GITLAB_TOKEN` key-value pair

These API tokens should have permissions to read the list of private repositories provided as arguments.

We recommend using Github's ['fine-grained' access tokens](https://github.blog/2022-10-18-introducing-fine-grained-personal-access-tokens-for-github/).
These tokens are repo-scoped, and avoid granting read permission across all of a user's private repos.

**Parameters**

<Parameter name="*repositories" type="str" description="Git URLs without scheme, e.g. ``github.com/org/repo@ref`` or with ``#subdirectory=``." />
<Parameter name="git_user" type="str" description="Username embedded in HTTPS git URLs for authentication." />
<Parameter name="find_links" type="str | None" defaultValue="None" description="Passed as ``--find-links`` to pip." />
<Parameter name="index_url" type="str | None" defaultValue="None" description="Passed as ``--index-url`` to pip." />
<Parameter name="extra_index_url" type="str | None" defaultValue="None" description="Passed as ``--extra-index-url`` to pip." />
<Parameter name="pre" type="bool" defaultValue="False" description="If True, allow pre-release versions." />
<Parameter name="extra_options" type="str" defaultValue="&quot;&quot;" description="Additional raw options for pip." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU type to attach to the builder container." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables set in the build container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets that supply ``GITHUB_TOKEN`` / ``GITLAB_TOKEN`` as required." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />

**Returns**

A new `Image` with private repositories installed.

**Usage**

```python
image = (
    modal.Image
    .debian_slim()
    .pip_install_private_repos(
        "github.com/ecorp/private-one@1.0.0",
        "github.com/ecorp/private-two@main"
        "github.com/ecorp/private-three@d4776502"
        # install from 'inner' directory on default branch.
        "github.com/ecorp/private-four#subdirectory=inner",
        git_user="erikbern",
        secrets=[modal.Secret.from_name("github-read-private")],
    )
)
```

## pip_install_from_requirements

```python
pip_install_from_requirements(self, requirements_txt, find_links=None, *,
    index_url=None, extra_index_url=None, pre=False, extra_options="",
    force_build=False, env=None, secrets=None, gpu=None)
```
Install a list of Python packages from a local `requirements.txt` file.

**Parameters**

<Parameter name="requirements_txt" type="str" description="Path to a ``requirements.txt`` file on the local machine." />
<Parameter name="find_links" type="str | None" defaultValue="None" description="Passed as ``--find-links`` to pip." />
<Parameter name="index_url" type="str | None" defaultValue="None" description="Passed as ``--index-url`` to pip." />
<Parameter name="extra_index_url" type="str | None" defaultValue="None" description="Passed as ``--extra-index-url`` to pip." />
<Parameter name="pre" type="bool" defaultValue="False" description="If True, allow pre-release versions." />
<Parameter name="extra_options" type="str" defaultValue="&quot;&quot;" description="Additional raw options for pip." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables set in the build container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets injected as environment variables during the build." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU type to attach to the builder container." />

**Returns**

A new `Image` with requirements installed.

## pip_install_from_pyproject

```python
pip_install_from_pyproject(self, pyproject_toml, optional_dependencies=[], *,
    find_links=None, index_url=None, extra_index_url=None, pre=False,
    extra_options="", force_build=False, env=None, secrets=None, gpu=None)
```
Install dependencies specified by a local `pyproject.toml` file.

`optional_dependencies` is a list of the keys of the
optional-dependencies section(s) of the `pyproject.toml` file
(e.g. test, doc, experiment, etc). When provided,
all of the packages in each listed section are installed as well.

**Parameters**

<Parameter name="pyproject_toml" type="str" description="Path to a ``pyproject.toml`` using PEP 621 ``[project.dependencies]``." />
<Parameter name="optional_dependencies" type="list[str]" defaultValue="[]" description="Keys under ``[project.optional-dependencies]`` to install additionally." />
<Parameter name="find_links" type="str | None" defaultValue="None" description="Passed as ``--find-links`` to pip." />
<Parameter name="index_url" type="str | None" defaultValue="None" description="Passed as ``--index-url`` to pip." />
<Parameter name="extra_index_url" type="str | None" defaultValue="None" description="Passed as ``--extra-index-url`` to pip." />
<Parameter name="pre" type="bool" defaultValue="False" description="If True, allow pre-release versions." />
<Parameter name="extra_options" type="str" defaultValue="&quot;&quot;" description="Additional raw options for pip." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables set in the build container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets injected as environment variables during the build." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU type to attach to the builder container." />

**Returns**

A new `Image` with project dependencies installed.

## uv_pip_install

```python
uv_pip_install(self, *packages, requirements=None, find_links=None,
    index_url=None, extra_index_url=None, pre=False, extra_options="",
    force_build=False, uv_version=None, env=None, secrets=None, gpu=None)
```
Install a list of Python packages using uv pip install.

This method assumes that:
- Python is on the ``$PATH`` and dependencies are installed with the first Python on the ``$PATH``.
- The shell supports ``$()``-style substitution as used in the generated Dockerfile.
- The ``command`` builtin is available on the ``$PATH``.

Added in v1.1.0.

**Parameters**

<Parameter name="*packages" type="str | list[str]" description="Python packages to pass to ``uv pip install``." />
<Parameter name="requirements" type="list[str] | None" defaultValue="None" description="Optional list of requirement file paths (passed as ``--requirements``)." />
<Parameter name="find_links" type="str | None" defaultValue="None" description="Passed as ``--find-links`` to ``uv pip``." />
<Parameter name="index_url" type="str | None" defaultValue="None" description="Passed as ``--index-url`` to ``uv pip``." />
<Parameter name="extra_index_url" type="str | None" defaultValue="None" description="Passed as ``--extra-index-url`` to ``uv pip``." />
<Parameter name="pre" type="bool" defaultValue="False" description="If True, allow pre-releases (``--prerelease allow``)." />
<Parameter name="extra_options" type="str" defaultValue="&quot;&quot;" description="Additional raw options appended to the ``uv pip install`` invocation." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />
<Parameter name="uv_version" type="str | None" defaultValue="None" description="Pin the uv binary version copied from ``ghcr.io/astral-sh/uv``." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables set in the build container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets injected as environment variables during the build." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU type to attach to the builder container." />

**Returns**

A new `Image` with packages installed via uv.

**Usage**

```python
image = modal.Image.debian_slim().uv_pip_install("torch==2.7.1", "numpy")
```

## poetry_install_from_file

```python
poetry_install_from_file(self, poetry_pyproject_toml, poetry_lockfile=None, *,
    ignore_lockfile=False, force_build=False, with_=[], without=[], only=[],
    poetry_version="latest", old_installer=False, env=None, secrets=None,
    gpu=None)
```
Install poetry *dependencies* specified by a local `pyproject.toml` file.

If not provided as argument the path to the lockfile is inferred. However, the
file has to exist, unless `ignore_lockfile` is set to `True`.

Note that the root project of the poetry project is not installed, only the dependencies.
For including local python source files see `add_local_python_source`

Poetry will be installed to the Image (using pip) unless `poetry_version` is set to None.
Note that the interpretation of `poetry_version="latest"` depends on the Modal Image Builder
version, with versions 2024.10 and earlier limiting poetry to 1.x.

**Parameters**

<Parameter name="poetry_pyproject_toml" type="str" description="Path to a Poetry ``pyproject.toml`` file." />
<Parameter name="poetry_lockfile" type="str | None" defaultValue="None" description="Path to ``poetry.lock``; if omitted, inferred next to the pyproject." />
<Parameter name="ignore_lockfile" type="bool" defaultValue="False" description="If True, do not copy or use a lockfile even when present." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />
<Parameter name="with_" type="list[str]" defaultValue="[]" description="Optional dependency groups to include (``poetry install --with``)." />
<Parameter name="without" type="list[str]" defaultValue="[]" description="Optional dependency groups to exclude (``poetry install --without``)." />
<Parameter name="only" type="list[str]" defaultValue="[]" description="Only install dependency groups in this list (``poetry install --only``)." />
<Parameter name="poetry_version" type="str | None" defaultValue="&quot;latest&quot;" description="Poetry version specifier to ``pip install``, or None to skip installing Poetry." />
<Parameter name="old_installer" type="bool" defaultValue="False" description="If True, use Poetry&#x27;s legacy installer." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables set in the build container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets injected as environment variables during the build." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU type to attach to the builder container." />

**Returns**

A new `Image` with Poetry dependencies installed.

## uv_sync

```python
uv_sync(self, uv_project_dir="./", *, force_build=False, groups=None,
    extras=None, frozen=True, extra_options="", uv_version=None, env=None,
    secrets=None, gpu=None)
```
Creates a virtual environment with the dependencies in a uv managed project with `uv sync`.

The `pyproject.toml` and `uv.lock` in `uv_project_dir` are automatically added to the build context. The
`uv_project_dir` is relative to the current working directory of where `modal` is called.

NOTE: This does *not* install the project itself into the environment (this is equivalent to the
`--no-install-project` flag in the `uv sync` command) and you would be expected to add any local python source
files using `Image.add_local_python_source` or similar methods after this call.

This ensures that updates to your project code wouldn't require reinstalling third-party dependencies
after every change.

uv workspaces are currently not supported.

Added in v1.1.0.

**Parameters**

<Parameter name="uv_project_dir" type="str" defaultValue="&quot;./&quot;" description="Path to the local uv project directory (contains ``pyproject.toml``)." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />
<Parameter name="groups" type="list[str] | None" defaultValue="None" description="Dependency groups passed as ``uv sync --group``." />
<Parameter name="extras" type="list[str] | None" defaultValue="None" description="Optional extras passed as ``uv sync --extra``." />
<Parameter name="frozen" type="bool" defaultValue="True" description="If True and a ``uv.lock`` exists, run ``uv sync --frozen`` so the lock is not updated at build time." />
<Parameter name="extra_options" type="str" defaultValue="&quot;&quot;" description="Additional raw options appended to ``uv sync``." />
<Parameter name="uv_version" type="str | None" defaultValue="None" description="Pin the uv binary version copied from ``ghcr.io/astral-sh/uv``." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables set in the build container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets injected as environment variables during the build." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU type to attach to the builder container." />

**Returns**

A new `Image` with a uv-managed virtual environment.

**Usage**

```python
image = modal.Image.debian_slim().uv_sync()
```

## dockerfile_commands

```python
dockerfile_commands(self, *dockerfile_commands, context_files={}, env=None,
    secrets=None, gpu=None, context_dir=None, force_build=False,
    ignore=AUTO_DOCKERIGNORE, build_args={})
```
Extend an image with arbitrary Dockerfile-like commands.

**Parameters**

<Parameter name="*dockerfile_commands" type="str | list[str]" description="Dockerfile lines to append after ``FROM base`` (strings or nested lists)." />
<Parameter name="context_files" type="dict[str, str]" defaultValue="&#123;&#125;" description="Map of container paths to local files to include in the build context." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables set in the build container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets injected as environment variables during the build." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU type to attach to the builder container." />
<Parameter name="context_dir" type="Path | str | None" defaultValue="None" description="Root directory for resolving relative COPY paths in implicit context mounts." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />
<Parameter name="ignore" type="Sequence[str] | Callable[[Path], bool]" defaultValue="AUTO_DOCKERIGNORE" description="Ignore rules for the implicit context mount (defaults to auto ``.dockerignore`` behavior)." />
<Parameter name="build_args" type="dict[str, str]" defaultValue="&#123;&#125;" description="Dockerfile ``ARG`` values forwarded to the build." />

**Returns**

A new `Image` with the Dockerfile fragment applied.

**Usage**

```python
from modal import FilePatternMatcher

# By default a .dockerignore file is used if present in the current working directory
image = modal.Image.debian_slim().dockerfile_commands(
    ["COPY data /data"],
)

image = modal.Image.debian_slim().dockerfile_commands(
    ["COPY data /data"],
    ignore=["*.venv"],
)

image = modal.Image.debian_slim().dockerfile_commands(
    ["COPY data /data"],
    ignore=lambda p: p.is_relative_to(".venv"),
)

image = modal.Image.debian_slim().dockerfile_commands(
    ["COPY data /data"],
    ignore=FilePatternMatcher("**/*.txt"),
)

# When including files is simpler than excluding them, you can use the `~` operator to invert the matcher.
image = modal.Image.debian_slim().dockerfile_commands(
    ["COPY data /data"],
    ignore=~FilePatternMatcher("**/*.py"),
)

# You can also read ignore patterns from a file.
image = modal.Image.debian_slim().dockerfile_commands(
    ["COPY data /data"],
    ignore=FilePatternMatcher.from_file("/path/to/dockerignore"),
)
```

## entrypoint

```python
entrypoint(self, entrypoint_commands)
```
Set the ENTRYPOINT for the image.

**Parameters**

<Parameter name="entrypoint_commands" type="list[str]" description="argv tokens for the ``ENTRYPOINT`` JSON array form." />

**Returns**

A new `Image` with the entrypoint Dockerfile directive applied.

## shell

```python
shell(self, shell_commands)
```
Overwrite default shell for the image.

**Parameters**

<Parameter name="shell_commands" type="list[str]" description="argv tokens for the ``SHELL`` JSON array form." />

**Returns**

A new `Image` with the shell Dockerfile directive applied.

## run_commands

```python
run_commands(self, *commands, env=None, secrets=None, volumes=None, gpu=None,
    force_build=False)
```
Extend an image with a list of shell commands to run.

**Parameters**

<Parameter name="*commands" type="str | list[str]" description="Shell commands to run as separate ``RUN`` lines (strings or nested lists)." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables set in the build container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets injected as environment variables during the build." />
<Parameter name="volumes" type="dict[str | PurePosixPath, _Volume] | None" defaultValue="None" description="Modal volumes to attach during the build step." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU type to attach to the builder container." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />

**Returns**

A new `Image` with the commands executed as layers.

## micromamba

```python
micromamba(python_version=None, force_build=False)
```
A Micromamba base image. Micromamba allows for fast building of small Conda-based containers.

**Parameters**

<Parameter name="python_version" type="str | None" defaultValue="None" description="Python series or full version to install in the base conda environment." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />

**Returns**

A Micromamba-based `Image`.

## micromamba_install

```python
micromamba_install(self, *packages, spec_file=None, channels=[],
    force_build=False, env=None, secrets=None, gpu=None)
```
Install a list of additional packages using micromamba.

**Parameters**

<Parameter name="*packages" type="str | list[str]" description="Conda packages to install, e.g. ``numpy`` or version constraints." />
<Parameter name="spec_file" type="str | None" defaultValue="None" description="Optional local path to a conda spec file to pass with ``-f``." />
<Parameter name="channels" type="list[str]" defaultValue="[]" description="Conda channels to pass with repeated ``-c`` flags." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables set in the build container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets injected as environment variables during the build." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU type to attach to the builder container." />

**Returns**

A new `Image` with micromamba packages installed.

## from_registry

```python
from_registry(tag, secret=None, *, setup_dockerfile_commands=[],
    force_build=False, add_python=None, **kwargs)
```
Build a Modal Image from a public or private image registry, such as Docker Hub.

The image must be built for the `linux/amd64` platform.

If your image does not come with Python installed, you can use the `add_python` parameter
to specify a version of Python to add to the image. Otherwise, the image is expected to
have Python on PATH as `python`, along with `pip`.

You may also use `setup_dockerfile_commands` to run Dockerfile commands before the
remaining commands run. This might be useful if you want a custom Python installation or to
set a `SHELL`. Prefer `run_commands()` when possible though.

To authenticate against a private registry with static credentials, you must set the `secret` parameter to
a `modal.Secret` containing a username (`REGISTRY_USERNAME`) and
an access token or password (`REGISTRY_PASSWORD`).

To authenticate against private registries with credentials from a cloud provider,
use `Image.from_gcp_artifact_registry()` or `Image.from_aws_ecr()`.

**Parameters**

<Parameter name="tag" type="str" description="Registry image reference (e.g. ``python:3.11-slim``)." />
<Parameter name="secret" type="_Secret | None" defaultValue="None" description="Optional secret for static registry credentials." />
<Parameter name="setup_dockerfile_commands" type="list[str]" defaultValue="[]" description="Extra Dockerfile lines run after ``FROM`` during base setup." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />
<Parameter name="add_python" type="str | None" defaultValue="None" description="Optional standalone Python series to inject when the base image lacks Python." />
<Parameter name="**kwargs" type="" description="Additional arguments forwarded to the internal image constructor (e.g. registry config)." />

**Returns**

An `Image` based on the registry tag.

**Usage**

```python
modal.Image.from_registry("python:3.11-slim-bookworm")
modal.Image.from_registry("ubuntu:22.04", add_python="3.11")
modal.Image.from_registry("nvcr.io/nvidia/pytorch:22.12-py3")
```

## from_gcp_artifact_registry

```python
from_gcp_artifact_registry(tag, secret=None, *, setup_dockerfile_commands=[],
    force_build=False, add_python=None, **kwargs)
```
Build a Modal image from a private image in Google Cloud Platform (GCP) Artifact Registry.

You will need to pass a `modal.Secret` containing [your GCP service account key data](https://cloud.google.com/iam/docs/keys-create-delete#creating)
as `SERVICE_ACCOUNT_JSON`. This can be done from the [Secrets](https://modal.com/secrets) page.
Your service account should be granted a specific role depending on the GCP registry used:

- For Artifact Registry images (`pkg.dev` domains) use
  the ["Artifact Registry Reader"](https://cloud.google.com/artifact-registry/docs/access-control#roles) role
- For Container Registry images (`gcr.io` domains) use
  the ["Storage Object Viewer"](https://cloud.google.com/artifact-registry/docs/transition/setup-gcr-repo) role

**Note:** This method does not use `GOOGLE_APPLICATION_CREDENTIALS` as that
variable accepts a path to a JSON file, not the actual JSON string.

See `Image.from_registry()` for information about the other parameters.

**Parameters**

<Parameter name="tag" type="str" description="Full GCP Artifact Registry image reference." />
<Parameter name="secret" type="_Secret | None" defaultValue="None" description="Secret containing ``SERVICE_ACCOUNT_JSON`` for registry authentication." />
<Parameter name="setup_dockerfile_commands" type="list[str]" defaultValue="[]" description="Extra Dockerfile lines run after ``FROM`` during base setup." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />
<Parameter name="add_python" type="str | None" defaultValue="None" description="Optional standalone Python series to inject when the base image lacks Python." />
<Parameter name="**kwargs" type="" description="Additional arguments forwarded to `from_registry`." />

**Returns**

An `Image` based on the private GCP artifact.

**Usage**

```python
modal.Image.from_gcp_artifact_registry(
    "us-east1-docker.pkg.dev/my-project-1234/my-repo/my-image:my-version",
    secret=modal.Secret.from_name(
        "my-gcp-secret",
        required_keys=["SERVICE_ACCOUNT_JSON"],
    ),
    add_python="3.11",
)
```

## from_aws_ecr

```python
from_aws_ecr(tag, secret=None, *, setup_dockerfile_commands=[],
    force_build=False, add_python=None, **kwargs)
```
Build a Modal image from a private image in AWS Elastic Container Registry (ECR).

You will need to pass a `modal.Secret` containing either IAM user credentials or OIDC
configuration to access the target ECR registry.

For IAM user authentication, set `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_REGION`.

For OIDC authentication, set `AWS_ROLE_ARN` and `AWS_REGION`.

IAM configuration details can be found in the AWS documentation for
["Private repository policies"](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-policies.html).

For more details on using an AWS role to access ECR, see the [OIDC integration guide](https://modal.com/docs/guide/oidc-integration).

See `Image.from_registry()` for information about the other parameters.

**Parameters**

<Parameter name="tag" type="str" description="Full ECR image URI." />
<Parameter name="secret" type="_Secret | None" defaultValue="None" description="Secret with IAM or OIDC credentials for ECR." />
<Parameter name="setup_dockerfile_commands" type="list[str]" defaultValue="[]" description="Extra Dockerfile lines run after ``FROM`` during base setup." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />
<Parameter name="add_python" type="str | None" defaultValue="None" description="Optional standalone Python series to inject when the base image lacks Python." />
<Parameter name="**kwargs" type="" description="Additional arguments forwarded to `from_registry`." />

**Returns**

An `Image` based on the private ECR image.

**Usage**

```python
modal.Image.from_aws_ecr(
    "000000000000.dkr.ecr.us-east-1.amazonaws.com/my-private-registry:my-version",
    secret=modal.Secret.from_name(
        "aws",
        required_keys=["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY", "AWS_REGION"],
    ),
    add_python="3.11",
)
```

## from_dockerfile

```python
from_dockerfile(path, *, force_build=False, context_dir=None, env=None,
    secrets=None, gpu=None, add_python=None, build_args={},
    ignore=AUTO_DOCKERIGNORE)
```
Build a Modal image from a local Dockerfile.

If your Dockerfile does not have Python installed, you can use the `add_python` parameter
to specify a version of Python to add to the image.

**Parameters**

<Parameter name="path" type="str | Path" description="Path to the Dockerfile on the local machine." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />
<Parameter name="context_dir" type="Path | str | None" defaultValue="None" description="Build context directory for resolving relative COPY paths." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables set in the build container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets injected as environment variables during the build." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU type to attach to the builder container." />
<Parameter name="add_python" type="str | None" defaultValue="None" description="Standalone Python version to add when the Dockerfile does not install Python." />
<Parameter name="build_args" type="dict[str, str]" defaultValue="&#123;&#125;" description="Dockerfile ``ARG`` values forwarded to the build." />
<Parameter name="ignore" type="Sequence[str] | Callable[[Path], bool]" defaultValue="AUTO_DOCKERIGNORE" description="Ignore rules for the implicit context mount (defaults to auto ``.dockerignore`` behavior)." />

**Returns**

An `Image` built from the Dockerfile plus Modal runtime dependencies.

**Usage**

```python
from modal import FilePatternMatcher

# By default a .dockerignore file is used if present in the current working directory
image = modal.Image.from_dockerfile(
    "./Dockerfile",
    add_python="3.12",
)

image = modal.Image.from_dockerfile(
    "./Dockerfile",
    add_python="3.12",
    ignore=["*.venv"],
)

image = modal.Image.from_dockerfile(
    "./Dockerfile",
    add_python="3.12",
    ignore=lambda p: p.is_relative_to(".venv"),
)

image = modal.Image.from_dockerfile(
    "./Dockerfile",
    add_python="3.12",
    ignore=FilePatternMatcher("**/*.txt"),
)

# When including files is simpler than excluding them, you can use the `~` operator to invert the matcher.
image = modal.Image.from_dockerfile(
    "./Dockerfile",
    add_python="3.12",
    ignore=~FilePatternMatcher("**/*.py"),
)

# You can also read ignore patterns from a file.
image = modal.Image.from_dockerfile(
    "./Dockerfile",
    add_python="3.12",
    ignore=FilePatternMatcher.from_file("/path/to/dockerignore"),
)
```

## from_scratch

```python
from_scratch(force_build=False)
```
Create an empty Image, equivalent to `FROM scratch` in Docker.

The resulting Image has no operating system, shell, or package manager. It is
primarily useful as a lightweight filesystem to mount into a Sandbox via
`Sandbox.mount_image`.

Note that since this Image doesn't contain Python or other standard OS utilities,
higher-level Image build steps like `pip_install` cannot be chained onto it. It also
cannot be used for `modal.Function` execution, which requires a Python interpreter.

**Parameters**

<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />

**Returns**

An empty `Image` suitable for minimal filesystem mounts.

**Usage**

```python notest
image = modal.Image.from_scratch().add_local_file(local_path, "/bin/my_binary", copy=True)
```

## debian_slim

```python
debian_slim(python_version=None, force_build=False)
```
Default image, based on the official `python` Docker images.

**Parameters**

<Parameter name="python_version" type="str | None" defaultValue="None" description="Python series or full version to use from the Debian slim images." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />

**Returns**

The standard Debian slim Python `Image` used as Modal's default base.

## apt_install

```python
apt_install(self, *packages, force_build=False, env=None, secrets=None,
    gpu=None)
```
Install a list of Debian packages using `apt`.

**Parameters**

<Parameter name="*packages" type="str | list[str]" description="Apt package names to install, e.g. ``git`` or ``libpq-dev``." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables set in the build container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets injected as environment variables during the build." />
<Parameter name="gpu" type="str | None" defaultValue="None" description="GPU type to attach to the builder container." />

**Returns**

A new `Image` with ``apt-get install`` layers applied.

**Usage**

```python
image = modal.Image.debian_slim().apt_install("git")
```

## run_function

```python
run_function(self, raw_f, *, env=None, secrets=None, volumes={},
    network_file_systems={}, gpu=None, cpu=None, memory=None, timeout=60 * 60,
    cloud=None, region=None, force_build=False, args=(), kwargs={},
    include_source=True)
```
Run user-defined function `raw_f` as an image build step.

The function runs like an ordinary Modal Function, accepting a resource configuration and integrating
with Modal features like Secrets and Volumes. Unlike ordinary Modal Functions, any changes to the
filesystem state will be captured on container exit and saved as a new Image.

Only the source code of `raw_f`, the contents of `**kwargs`, and any referenced *global* variables
are used to determine whether the image has changed and needs to be rebuilt.
If this function references other functions or variables, the image will not be rebuilt if you
make changes to them. You can force a rebuild by changing the function's source code itself.

**Parameters**

<Parameter name="raw_f" type="Callable[..., Any]" description="Callable executed remotely during the image build." />
<Parameter name="env" type="dict[str, str | None] | None" defaultValue="None" description="Environment variables set in the builder container." />
<Parameter name="secrets" type="Collection[_Secret] | None" defaultValue="None" description="Secrets available to the builder function." />
<Parameter name="volumes" type="dict[str | PurePosixPath, _Volume | _CloudBucketMount]" defaultValue="&#123;&#125;" description="Volume and bucket mounts attached for the build." />
<Parameter name="network_file_systems" type="dict[str | PurePosixPath, _NetworkFileSystem]" defaultValue="&#123;&#125;" description="Network file systems attached for the build." />
<Parameter name="gpu" type="str | list[str] | None" defaultValue="None" description="GPU type or list of types for the builder container." />
<Parameter name="cpu" type="float | None" defaultValue="None" description="CPU cores to request (soft limit)." />
<Parameter name="memory" type="int | None" defaultValue="None" description="Memory to request in MiB (soft limit)." />
<Parameter name="timeout" type="int" defaultValue="60 * 60" description="Maximum build-step runtime in seconds." />
<Parameter name="cloud" type="str | None" defaultValue="None" description="Cloud provider for the builder function." />
<Parameter name="region" type="str | Sequence[str] | None" defaultValue="None" description="Region or regions for the builder function." />
<Parameter name="force_build" type="bool" defaultValue="False" description="If True, skip cached image builds." />
<Parameter name="args" type="Sequence[Any]" defaultValue="()" description="Positional arguments serialized to the builder function." />
<Parameter name="kwargs" type="dict[str, Any]" defaultValue="&#123;&#125;" description="Keyword arguments serialized to the builder function." />
<Parameter name="include_source" type="bool" defaultValue="True" description="Whether to include the function&#x27;s source in the builder image." />

**Returns**

A new `Image` capturing the filesystem after `raw_f` completes.

**Usage**

```python notest

def my_build_function():
    open("model.pt", "w").write("parameters!")

image = (
    modal.Image
        .debian_slim()
        .pip_install("torch")
        .run_function(my_build_function, secrets=[...], volumes={...})
)
```

## env

```python
env(self, vars)
```
Sets the environment variables in an Image.

**Parameters**

<Parameter name="vars" type="dict[str, str]" description="Map of environment variable names to string values." />

**Returns**

A new `Image` with ``ENV`` directives applied.

**Usage**

```python
image = (
    modal.Image.debian_slim()
    .env({"HF_HUB_ENABLE_HF_TRANSFER": "1"})
)
```

## workdir

```python
workdir(self, path)
```
Set the working directory for subsequent image build steps and function execution.

**Parameters**

<Parameter name="path" type="str | PurePosixPath" description="Working directory path inside the image." />

**Returns**

A new `Image` with ``WORKDIR`` applied.

**Usage**

```python
image = (
    modal.Image.debian_slim()
    .run_commands("git clone https://xyz app")
    .workdir("/app")
    .run_commands("yarn install")
)
```

## cmd

```python
cmd(self, cmd)
```
Set the default command (`CMD`) to run when a container is started.

Used with `modal.Sandbox`. Has no effect on `modal.Function`.

**Parameters**

<Parameter name="cmd" type="list[str]" description="argv tokens for the default container command." />

**Returns**

A new `Image` with ``CMD`` applied.

**Usage**

```python
image = (
    modal.Image.debian_slim().cmd(["python", "app.py"])
)
```

## pipe

```python
pipe(self, func, *args, **kwargs)
```
Apply a local function to expand the Image recipe.

This method can be useful for defining reusable Image build
recipes that compose well with the fluent Image builder interface.

**Example**

```python
def workspace_setup(image: modal.Image, repo: str) -> modal.Image:
    return image.run_commands(f"git clone {repo}").uv_pip_install(".")

image = (
    modal.Image.debian_slim()
    .apt_install("git")
    .pipe(workspace_setup, "https://github.com/example/repo.git")
)
```

## imports

```python
imports(self)
```
Used to import packages in global scope that are only available when running remotely.

By using this context manager you can avoid an `ImportError` due to not having certain
packages installed locally.

**Returns**

Context manager that records import failures until the image is hydrated in the remote environment.

**Usage**

```python notest
with image.imports():
    import torch
```

## from_name

```python
from_name(name, *, environment_name=None, client=None)
```
Reference a named Image that was previously published with `.publish()`.

Names can contain an optional `:tag` part. If no tag part is included, `":latest"` is used, matching
Docker conventions.

```python notest
image = modal.Image.from_name("my-image")     # references my-image:latest
image_v1 = modal.Image.from_name("my-image:v1")

@app.function(image=image)
def run():
    ...
```

## publish

```python
publish(self, name, *, environment_name=None, experimental_options=None,
    client=None)
```
Publish this image under the given name

The Image must already be created (typically by calling `image.build()` or `sandbox.snapshot_filesystem()`).

Image names can contain an explicit tag designation using `name:tag`. If no tag is included in the name,
`":latest"` is used, matching Docker conventions. To publish multiple tags, call `.publish()` once per tag.

```python notest
image = modal.Image.debian_slim().pip_install("numpy")
image.build(app)
image.publish("my-image-with-numpy")     # my-image-with-numpy:latest
image.publish("my-image-with-numpy:v1")
```

## logs


```python
logs: ImageLogsManager
```

Access logs for an `Image`.

Use [`fetch()`](#logsfetch)
to read logs for individual build layers and [`tail()`](#logstail)
to read the most recent logs.

**See Also**

- [`modal app logs`](https://modal.com/docs/cli/latest/app#modal-app-logs):
  CLI access to logs for an App.


### logs.fetch

```python
fetch(self, layers=1)
```
Fetch logs for the most recent Image build steps.

**Parameters**

<Parameter name="layers" type="int | None" defaultValue="1" description="The number of build layers to fetch, counting backward from the final Image. If None, logs are fetched for all build steps." />

### logs.tail

```python
tail(self, entries=100)
```
Fetch the most recent Image logs.

**Parameters**

<Parameter name="entries" type="int" defaultValue="100" description="The number of log entries to return." />
