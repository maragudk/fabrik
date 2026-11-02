# Sticky Sessions

Sticky Sessions enable [Server](/docs/guide/servers) workloads requiring strong container affinity guarantees for requests. This is useful for allowing WebSocket connections to reconnect to the same container, supporting applications like collaborative editors, gaming, and multi-user rooms for voice and/or video.

A client can then start one or more sessions on a Server container. All requests made to a session will be routed to the same container for the session's lifetime. A session is active until explicitly terminated or if it has had no requests in-flight for `idle_timeout` seconds (600s by default). A container remains alive as long as it hosts an active session up until the container's max runtime.

In contrast, the affinity routing built into [Modal Servers](/docs/guide/servers#request-routing) is a best-effort hint: the routing proxy hashes a `Modal-Routing-Affinity-Key` header to bias requests toward a container, but that container can still be scaled down or replaced at any time.

## Defining a Server with Sticky Sessions

Users can add Sticky Session capabilities to a Server by using the `@modal.sessioned()` decorator together with `@app.server()`. Adding the decorator to an active Server app will start rejecting any new traffic without an attached session token.

```python
@app.server()
@modal.sessioned()
class Server:

    @modal.enter()
    def startup(self):
        ...
```

Note: `@modal.sessioned()` can only be applied to a [Server](/docs/guide/servers).

## Starting and using a Sticky Session

Sessions have a lifecycle during which they can serve one or more requests belonging to it.

Calling `Server.sessions.start()` creates a session and assigns it to a container, spinning one up if necessary, and returns a `session_id` and a session token. Any HTTP request (including WebSocket handshake) that carries the token as a `Modal-Authorization: Bearer <token>` header is routed deterministically to that container. Every request forwarded to the container carries the `x-modal-server-session-id` header containing the `session_id` (`sd-...`) for the request's session. This can be used to associate requests received by the Server with their sessions.

A session will end once it reaches its configured idle timeout naturally. It can also be
ended explicitly through a terminate request. A terminated session waits for any in-flight
requests to complete, rejecting any new requests.

```python notest
server = modal.Server.from_name("my-app", "Server")

session_creds = server.sessions.start(idle_timeout=600)

headers = {"Modal-Authorization": f"Bearer {session_creds.token}"}
requests.get(server.get_url(), headers=headers).raise_for_status()

server.sessions.terminate(session_creds.token)
```

Sessions can be managed outside the SDK with raw HTTP requests as well. In the examples below, `PROXY_AUTH_TOKEN` is a [Proxy Token](/docs/guide/webhook-proxy-auth) in the combined `wk-<id>.ws-<secret>` format, and `SESSION_TOKEN` is the token returned when starting a session:

```bash
# Start a session with a 600s idle timeout.
curl -X POST "$SERVER_URL/_modal/sessions/start" \
  -H "Authorization: Bearer $PROXY_AUTH_TOKEN" \
  -H "x-modal-server-session-idle-timeout: 600"
# Returns {"session_id": "sd-...", "token": "..."}

# Make a request to the session.
curl "$SERVER_URL/some/path" \
  -H "Modal-Authorization: Bearer $SESSION_TOKEN"

# Terminate the session early.
curl -X POST "$SERVER_URL/_modal/sessions/terminate" \
  -H "Authorization: Bearer $PROXY_AUTH_TOKEN" \
  -H "x-modal-server-session-token: $SESSION_TOKEN"
```

## Authorization

Starting or terminating a session follows normal [request authentication for Servers](/docs/guide/servers#request-authentication).

To make requests belonging to a session, include its session token in the `Modal-Authorization: Bearer <token>` header. A [Proxy Token](/docs/guide/webhook-proxy-auth) is not required. The session token is required even if the Server sets `unauthenticated=True`. Any non-session traffic, i.e. a request without a session token, to a Sessioned Server is rejected and such workloads should use Servers.

For browser clients, requests can also authenticate by passing the token as a `modal_session_token` query parameter. The proxy checks for, in order, a `Modal-Authorization` header, a query parameter, or a session cookie. A request authenticated using a query parameter is redirected to the same URL with a session cookie set.

All Modal Authorization query parameters and headers are stripped before the request is forwarded to the container.

```bash
# On first visit: authenticate via the query parameter.
curl -i "$SERVER_URL/?modal_session_token=$SESSION_TOKEN"
# HTTP/1.1 307 Temporary Redirect
# location: <SERVER_URL>/
# set-cookie: __Host-modal-session-token=<token>; Path=/; Secure; HttpOnly; SameSite=Lax
# cache-control: no-store

# A browser follows the redirect automatically and is left with the cookie.
# subsequent requests need neither the header nor the query parameter.
curl -i "$SERVER_URL/" --cookie "__Host-modal-session-token=$SESSION_TOKEN"
# HTTP/1.1 200 OK
```

WebSocket requests are supported by making a bootstrap HTTP request to exchange the query parameter token for a session cookie before the upgrade request.

## Session concurrency and autoscaling

Servers with the `@modal.sessioned` decorator also support setting max concurrency and target concurrency. Unlike Functions and Servers which scale based on [inputs](/docs/guide/servers#concurrency-and-autoscaling) and [concurrent requests](/docs/guide/functions#autoscaling-and-parallelism) respectively, the unit of concurrency for a Sessioned Server is a session. A single container will admit up to `max_concurrency` (1000 by default) active sessions at any given time. When target concurrency is unset, it defaults to `max_concurrency` and an additional session start request beyond this limit triggers scale up of an additional container (unless `max_containers` is reached). `max_concurrency` is capped to 1000 sessions per container.

For more aggressive autoscaling even when headroom is available, the Server may specify a target concurrency, where `0 < target_concurrency <= max_concurrency <= 1000`.

The other Server autoscaling controls e.g. scaleup/scaledown window, buffer containers, etc. can be set as well for further tuning. See [Server concurrency and autoscaling](/docs/guide/servers#concurrency-and-autoscaling) for more details.

## Queuing

Unlike a request to a non-sessioned Server which is rejected immediately if it can't be routed to a container, session creation queues for capacity for up to 5 minutes. Queuing only applies to session starts.

## Example

See the [sessioned WebSocket chat room example](/docs/examples/sessioned_chatroom) for a basic use case of Sticky Sessions.

We also have examples which leverage Sessions and WebRTC with both [LiveKit](https://modal.com/blog/livekit-modal) and [Pipecat](https://github.com/modal-projects/modal-phonon-voice-bot).
