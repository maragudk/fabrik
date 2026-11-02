# Servers

Modal Servers are a serverless compute primitive optimized for low-latency HTTP communication between external clients and a process running in a container on Modal.

```python
@app.server(unauthenticated=True)
class Server:

    @modal.enter()
    def startup(self):
        import subprocess
        subprocess.Popen("python -m http.server -d / 8000", shell=True)
```

The Modal Server primitive provides the underlying infrastructure for [Endpoints](/docs/guide/endpoints). They can also be deployed directly with fully customized application logic.

Modal Servers share many features with [Modal Functions](/docs/guide/functions). They are members of a Modal App and are [deployed](/docs/guide/managing-deployments) through the normal [`modal deploy`](/docs/cli/latest/deploy) workflow. Server resource configuration has the same [baseline request + burst semantics](/docs/guide/resources) as Functions, and of course they can use [GPUs](/docs/guide/gpu) too. With [`@modal.clustered`](/docs/guide/multi-node-clusters), Servers can run across multiple GPU nodes. Server containers can [run anywhere](/docs/guide/region-selection) in our global fleet, using [fully customized](/docs/guide/images) Images, and they benefit from the same snappy cold boot performance (including [memory snapshots](/docs/guide/memory-snapshots)). They can mount [Secrets](/docs/guide/secrets) and [Volumes](/docs/guide/volumes) and have a stable [outbound IP address](/docs/guide/proxy-ips).

This is a high-level guide to Modal Servers. For reference documentation, see the [`@app.server()`](/docs/sdk/py/latest/App#server) decorator and [`modal.Server`](/docs/sdk/py/latest/Server) object reference pages.

This guide emphasizes the *differences* between Servers and Functions. Servers were designed from the ground up to provide ultra-low latency for processes that listen on a port and speak HTTP natively. This motivates some important differences around autoscaling, load-leveling, authentication, and container lifecycle. It also means that Servers lack some operational features of Modal Functions that depend on the stateful Function input system.

## Defining a Server

A Modal Server is defined with a class that uses Modal’s [lifecycle decorators](/docs/guide/lifecycle-functions) on methods that specify container startup (and, optionally, shutdown) logic. The class itself is registered with an App using the `@app.server()` decorator, which takes the main set of Server configuration parameters.

The startup logic must initialize a server process that binds to 0.0.0.0 and listens on a port (`8000` by default).

Unlike a Modal Cls, Server definitions cannot use `@modal.method()` or Web Function decorators like `@modal.fastapi_endpoint`. The request handling is performed by the process listening on the port, not a method on the class.

A Modal Server is most directly analogous to a Modal Function using the `@modal.web_server()` decorator, and most web server Functions can be directly migrated to a Server, so long as the migration accounts for the different behaviors and configuration models discussed in this guide.

Every Server is assigned a URL as its public interface. A Server’s URL can be retrieved programmatically using `modal.Server.get_url()`.

## Concurrency and autoscaling

Modal Function containers process one input at a time unless they explicitly opt into [input concurrency](/docs/guide/concurrent-inputs), and Modal will [autoscale](/docs/guide/scale) additional Function containers to meet demand. Servers invert this: Server processes are expected to handle concurrent requests, and the Server configuration must explicitly opt into container autoscaling when desired.

To enable autoscaling, provide a `target_concurrency=` value in the `@app.server()` decorator. Modal will use this target to manage the Server’s container pool, scaling towards a desired number of containers based on each container’s concurrent request load. Note that it provides only a soft limit. If the Server process cannot handle a given level of request concurrency, the process must perform its own load-leveling or load-shedding.

Set `max_concurrency=` to a positive integer to impose a hard per-container request limit. It must be greater than or equal to `target_concurrency`. Requests routed to a container that is already at its limit receive a 429 Too Many Requests response. When `max_concurrency` is unset or `0`, request concurrency is unbounded. This limit does not affect autoscaling; configure `target_concurrency` separately to scale based on request load.

Servers can use the standard `min_containers=`, `max_containers=`, and `buffer_containers=` parameters to bound the autoscaler or to [keep additional containers warm](/docs/guide/cold-start). They can also use `scaleup_window=` and `scaledown_window=` to tune the autoscaler’s responsiveness to fluctuations in request rates. The Server autoscaling configuration can be viewed using `modal.Server.autoscaler.settings()`, and dynamically tuned using `modal.Server.autoscaler.update()`. As with Functions, any dynamic configuration will be reset by a subsequent deployment.

If the Server configuration leaves `target_concurrency=` unset but provisions multiple containers via `min_containers=`, requests will be distributed across the pool. If a singleton container is desired, it is preferable to leave `target_concurrency=` unset over setting `max_containers=1`, as the latter will prevent Modal from bringing up a replacement to gracefully shift traffic during a [rolling redeployment](/docs/guide/managing-deployments#deployment-strategies).

## Zero-to-one scaling

Because Servers use a stateless reverse proxy between clients and containers, requests do not queue while waiting for a container like Function inputs would. This has a significant consequence for zero-to-one scaling. When a Server has no active containers, requests will be rejected with a 503 Service Unavailable status, which clients must handle. Zero-to-one scaling is still automatic, so the first request will trigger a container cold start, and the Server will handle additional incoming requests as soon as it is ready.

## Container lifecycle

Server containers are not considered ready until the Server process is listening on the configured port, even if the startup methods have returned. Requests will be sent to other containers (or rejected with a 503) until the container is ready. Containers that do not become ready within `startup_timeout=` seconds will be terminated and marked as failed.

While a Server container is active, Modal will send health checks to verify that its port is still listening. If the container fails too many consecutive health checks, it will be terminated and replaced.

When containers are scaled down, they will stop receiving new requests, but they may continue processing any inflight requests for up to `exit_grace_period=` seconds (maximum 3600 seconds, or 1 hour). Subsequently, the container will be sent a SIGTERM to gracefully terminate all running processes and run any exit handlers (`@modal.exit()`). The process termination and exit handlers are given an additional 30s to complete, after which the container will receive a hard SIGKILL signal if it is still running.

## Request authentication

Unlike Web Functions, Servers require [authentication](/docs/guide/webhook-proxy-auth) in requests by default, and the Server configuration must set `unauthenticated=True` to accept public web traffic. Without this setting, unauthenticated requests will be denied by Modal’s proxy with a 401 code and will not contribute to autoscaler accounting.

To authenticate a request, pass a Proxy Token as a single `Authorization: Bearer wk-<id>.ws-<secret>` header, or as separate `Modal-Key` and `Modal-Secret` headers.

For Workspaces with [RBAC](/docs/guide/rbac) enabled, the Proxy Tokens must additionally be scoped to the Environment where the Server’s App is deployed. Valid tokens that are not scoped to the relevant Environment will be denied with a 403 code.

## Request routing

The Server configuration includes a region specification for the proxy that routes requests to containers (`routing_region=`). The following routing regions are supported: `us-east` (default), `us-west`, `ca-central`, `eu-west`, `ap-south`, and `ap-southeast-2`. As a general rule, select the routing region that will be closest to your clients. It’s also possible to constrain container scheduling within the same region using `compute_region=`, although note that this incurs a [cost multiplier](/docs/guide/region-selection#pricing).

The routing proxy additionally supports “affinity routing”. Requests that include a `Modal-Routing-Affinity-Key` header (which can be an arbitrary string) and share the routing header's value will be handled by the same container. This is best-effort, as request affinity may change e.g. in the event of a container scale-down or rollover. For strong request-container affinity, see [Sticky Sessions](/docs/guide/sticky-sessions).

## Operational features

Beyond request queueing, Servers lack several other operational features afforded by the stateful input system used for Modal Functions, and they require the user’s client or server application layer to implement those features when desired. Serialization and deserialization of request data must be handled at the application layer. There are no built-in [retries](/docs/guide/retries) for failed requests (including requests that fail when their container is [preempted](/docs/guide/preemption) or crashes). Request [timeouts](/docs/guide/timeouts) cannot be customized within Modal and must be set by the client or server code.
