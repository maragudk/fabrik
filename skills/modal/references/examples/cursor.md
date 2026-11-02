# Run Cursor Cloud Agents on Modal

Use [Cursor Self-Hosted Machines](https://cursor.com/docs/cloud-agent/self-hosted/pool)
to run Cursor Cloud Agent workers in [Modal Sandboxes](https://modal.com/docs/guide/sandboxes).
Select the pool in Cursor, and Modal Cursor starts a Modal Sandbox for each
Cloud Agent session.

## Before you begin

* Python 3.11 or newer
* [`uv`](https://docs.astral.sh/uv/)
* A [Modal account](https://modal.com/docs/guide/modal-user-account-setup)
* A Cursor service-account API key for pool workers

Install `uv` with the
[official standalone installer](https://docs.astral.sh/uv/getting-started/installation/)
if it is not already installed:

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

The default configuration uses a [Modal Secret](https://modal.com/docs/guide/secrets)
named `cursor-service-account` containing `CURSOR_API_KEY`.

`CURSOR_API_KEY` is a long-lived service-account key. It is available in each
Cursor worker's environment, so code running in a worker sandbox can read it.
Treat worker code and images as part of this key's trust boundary, and do not
print the key or include it in logs.

## Deploy a worker pool

Give the pool a recognizable name, such as `gpu-training`. You will select this
name in Cursor when starting a Cloud Agent session.

Run the interactive setup wizard:

```bash
uvx modal-cursor init
```

Run these commands from the directory where you want to keep the integration
configuration, such as the root of a small deployment repository. By default,
`init` writes `pools/<pool-name>.py` relative to the current directory. The
`deploy`, `doctor`, and `destroy` commands also look for pool files in `pools/`
relative to the current directory; use `--pools-dir` to use a different
directory.

The wizard configures Modal if needed, asks for a pool name and Cursor
service-account key, creates the `cursor-service-account` Secret, writes the
pool file, and offers to deploy it. Accept the deployment prompt to deploy the
Modal service that registers and serves the pool.

To review or edit the generated file before deploying, pass a name and
`--no-deploy` instead:

```bash
uvx modal-cursor init gpu-training --no-deploy
```

After editing, deploy all pool files in `pools/`:

```bash
uvx modal-cursor deploy
```

Verify the deployment:

```bash
uvx modal-cursor doctor
```

## Start a Cloud Agent

In Cursor, open the Cloud Agents dashboard and start a session using the
workflow you normally use. In the session's worker or machine selector, choose
the pool you created—in this example, `gpu-training`—before starting the session.
The pool is listed after deployment finishes and Cursor has received the pool;
run `uvx modal-cursor doctor` if it is not available.

After you start the session, Cursor places the request in that pool. Modal
Cursor claims it, creates a Modal sandbox, starts the Cursor worker, and waits
for Cursor to report the worker as connected. The session then runs on that
sandbox.

## Configure repositories and workers

The generated pool file is ordinary Python. For example, `uvx modal-cursor init
gpu-training` writes a file containing the pool and secret declarations below.
`CURSOR_SECRET_NAME` names the Modal Secret containing the Cursor
service-account key. Leave `WORKER_SECRET_NAMES` empty unless the worker needs
additional secrets; add the names of those Modal Secrets to it when needed.

```python notest
"""Generated configuration for one editable Cursor worker pool."""

import modal

from modal_cursor import Pool

CURSOR_SECRET_NAME = "cursor-service-account"
WORKER_SECRET_NAMES = ()

pool = Pool(name="gpu-training")
worker = pool.machine(
    image=pool.worker_image(),  # Add application-specific image layers here.
    secrets=[modal.Secret.from_name(name) for name in WORKER_SECRET_NAMES],
    # gpu="A10G",
    # cpu=4,
    # memory=16384,
)
```

Set worker resources in the `pool.machine()` call. See Modal's guides for
[GPU acceleration](https://modal.com/docs/guide/gpu) and [CPU, memory, and disk
configuration](https://modal.com/docs/guide/resources).

### Repository-scoped pools

To make a pool available for one repository, include its HTTPS GitHub URL when
generating the pool:

```bash
uvx modal-cursor init payments \
  --repo-url https://github.com/acme/payments \
  --no-deploy
```

Only URLs in the form `https://github.com/<owner>/<repo>` are accepted. The
repository URL associates requests for that repository with the pool.

For a private repository, add `--private-repo`. The wizard prompts for the
GitHub token and creates the `github-token` Secret:

```bash
uvx modal-cursor init payments \
  --repo-url https://github.com/acme/payments \
  --private-repo \
  --no-deploy
```

`GITHUB_TOKEN` is used only for the initial clone and is removed before the
Cursor worker starts. It is not embedded in the remote URL or available to the
worker. The worker can edit files and create local commits; fetching, pulling,
or pushing a private repository requires separate credentials configured for
the worker.

### Custom worker images

`pool.worker_image()` contains the pinned Cursor agent CLI and Git. Extend this
[Modal Image](https://modal.com/docs/guide/images) with tools or application
dependencies before passing it to `pool.machine()`:

```python notest
worker_image = (
    pool.worker_image()
    .apt_install("ripgrep")
    # .pip_install("your-application-dependency")
)

worker = pool.machine(
    image=worker_image,
    secrets=[modal.Secret.from_name(name) for name in WORKER_SECRET_NAMES],
    gpu="A10G",
)
```

`pool.machine()` is where you customize the worker image, resources, extra
secrets, and [Modal Sandbox](https://modal.com/docs/guide/sandboxes) settings.
Derive custom images from `pool.worker_image()` so the pinned Cursor agent CLI
and Git remain available. Add extra Modal Secret names to
`WORKER_SECRET_NAMES`.

After changing a pool file, deploy again:

```bash
uvx modal-cursor deploy
```

## Remove a deployment

To stop the Modal deployment and remove one pool from Cursor:

```bash
uvx modal-cursor destroy pools/gpu-training.py --yes
```

To remove all pools in `pools/`:

```bash
uvx modal-cursor destroy --yes
```

`destroy` stops the shared Modal deployment and removes the matching pool from
Cursor. Because all pool files use one shared service, destroying one pool also
stops new sessions for every pool until you deploy again. It does not delete
the local pool files or Modal Secrets.

Existing sessions and worker sandboxes are covered in the Reference section.

## Reference

### Architecture

The deployment has two parts:

* A single Modal application named `modal-cursor-control-plane` runs the
  controller for all pool files in `pools/`.
* Each claimed request creates one ephemeral Modal sandbox from its pool's
  `Machine` configuration.

The controller consumes Cursor's pending-request stream and routes requests by
the `pool` label. A worker connects to Cursor over an outbound connection, with
no inbound port or public IP address.

The integration passes each `Machine`'s image, worker secrets, environment,
timeout, and the shared Modal app to `modal.Sandbox.create`. Configure these
values through `pool.machine()`; do not pass `image`, `secrets`, `env`,
`timeout`, or `app` again through `sandbox_options`, because those fields are
reserved by modal-cursor.

### Stopping a deployment

`destroy` stops the `modal-cursor-control-plane` Modal application and removes
the Cursor pool records that match the pool files you selected. It stops the
controller's running container, but does not explicitly terminate worker
sandboxes for sessions that are already running. Those sessions can continue
until their worker exits or its sandbox lifetime or idle limit is reached. The
local pool files and Modal Secrets are preserved, and no new sessions are
claimed while the application is stopped.

### Request lifecycle

For a request assigned to a pool:

1. The controller discovers the pending request from Cursor.
2. It claims the request and obtains the worker identity.
3. It creates a Modal sandbox using the pool's `Machine` configuration.
4. The sandbox clones the requested repository, when applicable, and starts
   the Cursor worker CLI.
5. The controller polls Cursor until the worker is connected.

When the sandbox exits before connecting or the worker remains invisible through
the readiness timeout, provisioning fails and the claim is released for retry.

This integration registers `workerReadyTimeoutSeconds=0`. Workers run in
ephemeral sandboxes; snapshot/restore hibernation and nonzero reconnect windows
remain unavailable.

### Runtime settings

The following environment variables change lifecycle defaults for the controller
and workers:

| Variable | Purpose | Default |
| --- | --- | ---: |
| `MODAL_CURSOR_SANDBOX_TIMEOUT_S` | Maximum sandbox lifetime | `21600` |
| `MODAL_CURSOR_IDLE_RELEASE_TIMEOUT_S` | Idle time before release | `600` |
| `MODAL_CURSOR_SPAWNER_READY_TIMEOUT_S` | Worker registration wait | `120` |
| `MODAL_CURSOR_WORKER_POLL_INTERVAL_S` | Registration polling interval | `1` |
| `MODAL_CURSOR_CONTROLLER_TIMEOUT_S` | Controller invocation lifetime | `86400` |
| `MODAL_CURSOR_CONTROLLER_MAX_RETRIES` | Controller retry count | `10` |

Set `CURSOR_API_ENDPOINT` to use a different Cursor API endpoint. The default
is `https://api.cursor.com`; `modal-cursor init` can also write a custom
endpoint into a pool file.

### Observability

Set `OTEL_EXPORTER_OTLP_ENDPOINT` to export lifecycle and Cursor API spans over
OTLP/HTTP. Instrumentation exports telemetry only when an endpoint is set.
`OTEL_SERVICE_NAME` changes the emitted service name.

The spans include pool, request, worker, sandbox, and outcome metadata. They
omit Cursor API keys, Modal Secret values, and complete claim and machine
payloads.

### Credentials

The controller receives `CURSOR_API_KEY` from the `CURSOR_SECRET_NAME` Modal
Secret and passes it to the Cursor worker environment.

For private repositories, `GITHUB_TOKEN` is separate from the Cursor key and is
used only during the clone step. It is removed before the worker starts.

The [modal-cursor source repository](https://github.com/modal-labs/modal-cursor)
contains implementation details and the package release workflow.
