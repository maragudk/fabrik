# Getting started with Modal

Using Modal requires an account. If you or your organization do not yet have an account, visit the [signup](/signup) page to begin the process. Enterprise user accounts may also be managed via [SAML SSO](/docs/guide/saml-sso) or [SCIM](/docs/guide/scim).

You can also ask an agent to help you get set up:

```
Read https://modal.com/docs/guide/getting-started.md and walk me through Modal setup.
```

## Install the Modal CLI

The `modal` CLI is a key tool for interacting with the platform. It will be installed alongside the Python SDK:

{#snippet uv()}

```bash
uv add modal
```

{#snippet pip()}

```bash
pip install modal
```

{#snippet conda()}

```bash
conda install conda-forge::modal-client
```

If using Modal in a [TypeScript](/docs/sdk/js/latest) or [Go](/docs/sdk/go/latest) project, you can also install the CLI as a standalone tool via [`uvx.sh`](https://uvx.sh/):

```bash
curl -LsSf uvx.sh/modal/install.sh | sh
```

## Set up a Modal token

You'll need a Modal token to use service. After installing the CLI, run this command to configure your local system:

```bash
modal setup
```

This step requires a web browser for authentication. Once the setup flow completes, you can verify that the token works:

```bash
modal token info
```

## Install agent skills

Modal provides a [skill](https://github.com/modal-labs/modal-client/blob/main/py/modal/skills/modal/SKILL.md) that helps coding agents work most effectively with the platform.

The skill can be installed and maintained via the CLI:

```bash
modal skills install  # [--claude] [--global]
```

When installed via the CLI, the skill file will be versioned, and the skill references will be populated with version-aligned documentation.

The skill can also be managed via tools such as [`npx skills`](https://www.skills.sh/modal-labs/modal-client/modal), although it will not include additional reference documentation.

Because the skill is intended to keep agents up to date with the latest features, we encourage regular updates:

```bash
modal skills update  # [--claude] [--global]
```

## Test it out

Test your setup by running a simple script:

```python
import modal

app = modal.App("getting-started")


@app.function()
def square(x: int) -> int:
    print("Using cloud compute for advanced mathematics!")
    return x**2


@app.local_entrypoint()
def main(x: int = 42):
    print(f"The square of {x} is {square.remote(x)}")
```

Save this to `getting_started.py` and execute it with `modal run getting_started.py`.

Or ask your coding agent for a demo:

```
Write me a simple script that demonstrates the power of the Modal cloud platform.
```

## Next steps

* Learn about Modal's powerful compute primitives: [Function](/docs/guide/functions), [Sandbox](/docs/guide/sandboxes), and [Server](/docs/guide/servers)
* Set up a high-performance inference [Endpoint](/endpoints) with just a few clicks
* Check out the [examples](/docs/examples) to see what else you can do on Modal
* Install Modal's [JavaScript/TypeScript](/docs/sdk/js/latest) or [Go](/docs/sdk/go/latest) SDKs
