# Attributes for wide events

A working checklist of attributes to put on the main span / wide event, grouped by concern. Treat it as a menu, not a mandate: copy, prune what doesn't apply, and lean toward "add the attribute" when unsure -- columnar stores compress repeated values to near zero, and questions you can't ask cost more than dimensions you don't use. Well-instrumented services typically carry 50-300 dimensions per event.

Synthesized from Jeremy Morrell's "A Practitioner's Guide to Wide Events", Brandur Leach's "Canonical Log Lines" (Stripe), Charity Majors / Honeycomb, and the OpenTelemetry semantic conventions.

## Contents

- [Naming: use OTel semantic conventions](#naming-use-otel-semantic-conventions)
- [The attribute groups](#the-attribute-groups)
- [Patterns worth stealing](#patterns-worth-stealing)
- [Staged adoption](#staged-adoption)
- [Caveats](#caveats)

## Naming: use OTel semantic conventions

Prefer OTel semconv names when one exists, so vendors and shared libraries Just Work. Stable today: HTTP, exception/error attributes, core URL (`url.full`, `url.scheme`, `url.path`, `url.query`, `url.fragment`), `user_agent.original`, and `code.*` (`code.function.name`, `code.file.path`, `code.line.number`, `code.stacktrace`).

Many other namespaces (`enduser.*`, `feature_flag.*`, messaging, `session.*`, most resource conventions) are still marked Development and may rename. Where no stable name exists, pick a name and document it -- internal consistency matters more than chasing every spec revision.

Deprecated names worth knowing (don't use the old ones in new code):

| Deprecated | Current |
|------------|---------|
| `http.method` | `http.request.method` |
| `http.status_code` | `http.response.status_code` |
| `http.user_agent` | `user_agent.original` |
| `http.flavor` | `network.protocol.version` |
| `net.peer.*` / `net.host.*` | `client.*` / `server.*` |
| `db.system` | `db.system.name` |
| `db.statement` | `db.query.text` |
| `code.function` / `code.filepath` / `code.lineno` | `code.function.name` / `code.file.path` / `code.line.number` |
| `enduser.role` / `enduser.scope` | `user.roles` |

But don't stop at semconv: the highest-leverage attributes are the business, identity, tenancy, and feature-flag ones no SDK can auto-generate.

## The attribute groups

### Event identity

- `main` -- `true` on the one root/canonical span per request, so you can filter to request summaries without dragging in child spans.
- `event.name` / span name -- low-cardinality logical name (`http.server.request`, `cart.checkout`).
- `trace.id`, `span.id`, `parent.span.id` -- set by the SDK; expose the trace ID in responses (a `traceresponse` or custom header) so support can paste it back.
- `sample_rate` -- per-event, so weighted aggregates are correct (see Sampling in `instrumentation.md`).

### Service / resource (set once at startup)

- `service.name`, `service.namespace`, `service.instance.id`, `service.version`
- `deployment.environment.name` -- `production` | `staging` | `dev`
- `service.team`, `service.slack_channel` -- non-semconv but high-leverage during incidents.

### Build & deploy metadata

Answers "did something just go out?" in one query -- how most incidents get resolved.

- `vcs.ref.head.revision` (git hash), `service.build.id`
- `service.build.pull_request_url`
- `service.build.deployment.at`, `service.build.deployment.user`
- `service.build.deployment.trigger` -- `merge-to-main` | `manual` | `rollback` | `config-change`
- `service.build.deployment.age_minutes` -- shortcut for "did this just deploy?"

### Infrastructure / runtime

- `host.name`, `host.id`, `host.type`, `host.arch`
- `container.id`, `container.image.name`, `container.image.tag`
- `k8s.cluster.name`, `k8s.namespace.name`, `k8s.pod.name`, `k8s.node.name`
- `cloud.provider`, `cloud.region`, `cloud.availability_zone`
- `process.pid`, `process.runtime.name`, `process.runtime.version`
- `instance.memory_mb`, `instance.cpu_count` -- "is this load reasonable for this box?"
- `uptime_sec` -- and optionally a log-scaled twin (`uptime_sec_log10`) so brand-new and week-old instances graph on the same axis. Useful for spotting crash loops.

### HTTP request & response

Mostly auto-instrumented; verify the SDK actually populates them.

- `http.request.method`, `http.route` (the low-cardinality pattern `/users/{id}`, never the raw path), `url.path`, `url.query`, `url.scheme`
- `server.address`, `server.port`
- `http.request.body.size`, `http.response.body.size`
- `http.response.status_code`
- `http.request.header.<key>` -- explicit allowlist only (content-type, accept-language, x-request-id), never auth/cookie headers.
- `http.request.resend_count` -- retries.
- `http.route.param.<name>`, `http.route.query.<name>` -- extracted path/query params you care about (custom, high-leverage).

### Network / client

- `client.address` -- original client behind proxies (from `Forwarded`/`X-Forwarded-For`).
- `network.protocol.version` -- `1.1` | `2` | `3`
- `tls.protocol.version`, `tls.cipher` -- Stripe's TLS 1.0 to 1.2 migration was driven entirely by canonical-log-line queries on these.
- `geo.country.iso_code`, `geo.city.name` -- if you do IP-to-geo.

### User agent

Parse at ingest, don't regex later.

- `user_agent.original` (raw header), `user_agent.name`, `user_agent.version`
- `user_agent.os.name`, `user_agent.os.version`
- `user_agent.synthetic.type` -- `bot` | `test`
- For your own callers: `user_agent.app` / `user_agent.app_version` (mobile apps), `user_agent.service` / `user_agent.service_version` (service-to-service).

### Identity & authentication

The single most valuable group -- no SDK can guess your user model.

- `user.id` -- consider hashing/pseudonymizing for PII policy (`enduser.pseudo.id`).
- `user.type` -- `free` | `pro` | `enterprise` | `internal`
- `user.roles`
- `user.auth_method` -- `session-cookie` | `jwt` | `api-key` | `oauth` | `sso-google`
- `user.api_key.id` -- which key authenticated (never the secret itself).
- `user.assumed` (bool), `user.assumed_by` -- when staff impersonates a user, ALWAYS tag it.
- `user.age_days` -- separates "broke for new signups" from "broke for power users".
- `session.id`

### Tenancy / org / account

For B2B / multi-tenant apps -- a separate dimension from `user.*` because one user can hit multiple tenants.

- `tenant.id` / `org.id` / `account.id`, `tenant.name`
- `tenant.plan` -- `free` | `team` | `enterprise`
- `tenant.shard` / `tenant.region` -- if you partition data.

### Application / business context

The "go off the map" category -- your domain's nouns. This is where the real insight lives. Examples:

- `cart.id`, `cart.item_count`, `cart.total_cents`, `cart.currency`
- `order.id`, `order.status`
- `payment.processor`, `payment.method`, `payment.amount_cents`
- `workflow.id`, `workflow.step`, `workflow.state`
- `query.search_term_length`, `query.result_count`
- Vendor transaction IDs (`email_vendor.transaction_id`) -- invaluable for support escalations.

### Localization

A common source of subtle bugs: `localization.language`, `localization.language_dir`, `localization.country`, `localization.currency`, `localization.timezone`.

### Errors & exceptions

- `error.type` -- low-cardinality canonical class or domain code; leave unset on success so error rates are easy to derive.
- `exception.type`, `exception.message`, `exception.stacktrace`
- `exception.expected` (bool) -- filter out bot-hitting-404 noise.
- `exception.slug` -- a unique grep-able string per throw site (`err-stripe-call-failed-exhausted-retries`), so you can jump from a dashboard spike straight to the line of code.
- `code.function.name`, `code.file.path`, `code.line.number`

### Performance / timing breakdown

Don't wrap every sub-operation in a child span -- roll key phases up to the wide event:

- `duration_ms` (usually auto-set)
- `auth.duration_ms`, `payload_parse.duration_ms`, `db.duration_ms`, `render.duration_ms`, `external_calls.duration_ms`
- `queue.wait_ms` -- time in queue before processing, for jobs/consumers.

### Downstream-call summaries (rollups)

Even when downstream calls get child spans, summarize counts/totals on the wide event so you can `GROUP BY http.route` and instantly spot N+1 patterns:

- `stats.db.query_count`, `stats.db.query_duration_ms`, `stats.db.rows_returned`
- `stats.http.request_count`, `stats.http.request_duration_ms`
- `stats.<vendor>.calls_count`, `stats.<vendor>.calls_duration_ms` -- per vendor (stripe, twilio, ...).
- `stats.cache.hits`, `stats.cache.misses`

### Database child spans

- `db.system.name`, `db.namespace`, `db.collection.name`
- `db.operation.name` -- `SELECT` | `INSERT` (low cardinality), `db.query.summary`
- `db.query.text` -- sanitized SQL, opt-in, literals redacted.
- `db.response.returned_rows`, `db.operation.batch.size`

### Messaging / queue spans (producers, consumers, jobs)

- `messaging.system`, `messaging.operation.type` (`publish` | `receive` | `process`)
- `messaging.destination.name`, `messaging.message.id`
- `messaging.batch.message_count`, `messaging.consumer.group.name`
- `job.attempt`, `job.max_attempts`, `job.scheduled_at`, `job.delay_ms` -- custom, but every queue worker needs these.

### Caching, rate limiting, feature flags

- `cache.hit` (bool) -- or per-cache: `cache.session_info`, `cache.feature_flags`.
- `ratelimit.limit`, `ratelimit.remaining`, `ratelimit.bucket`, `ratelimit.action` (`allow` | `throttle` | `reject`)
- `feature_flag.<flag_name>` = value, one per flag in scope -- easy to `GROUP BY` for A/B comparisons. (OTel also defines a `feature_flag.evaluation` span event; both are reasonable.)

### Dependency versions

For "framework X just announced a CVE -- what's vulnerable?" queries: `go.version`, `node.version`, `<framework>.version`, datastore client/server versions.

### Inline system metrics snapshot (opt-in)

Attach a recently-cached host-metrics snapshot to every main span (via an OTel SpanProcessor) so you can correlate per-request slowness with host pressure in one query: `metrics.memory_pct`, `metrics.cpu_load`, `metrics.gc_pause_time_ms`, `metrics.goroutines_count`. Not statistically rigorous for alerting -- use real metrics for that -- but excellent for ad-hoc debugging.

## Patterns worth stealing

- **One wide event per request per service hop.** Decorate a shared span/event object throughout the request and emit it once at the end -- in a `defer`/`finally` block so it fires on errors too.
- **Tag the main span** (`main=true`) so request-summary queries don't drag in child spans.
- **Phase rollups over child-span sprawl.** If you're wrapping every function in a child span, stop: roll durations up to the main span as `<phase>.duration_ms`, and reach for child spans only when the waterfall actually helps.
- **Expose the trace ID to users** in a response header so support tickets come with a direct link to the evidence.

## Staged adoption

**Stage 1 -- the minimum that pays for itself (first afternoon):** one middleware that creates the main span and exposes a set-attributes helper to every handler, emitting in a `defer` block. Add event identity, service/resource, HTTP request/response, identity, and errors. This alone unlocks the majority of debugging wins.

**Stage 2 -- within the first sprint:** build/deploy metadata and feature flags (these answer "what changed?"), downstream-call rollups (finds N+1s immediately), and tenancy if multi-tenant.

**Stage 3 -- once the habit sticks:** business/application context in every handler, cache/rate-limit attributes, full semconv on DB/messaging child spans, the inline metrics snapshot, and uptime.

Rough calibration: if your wide events average under ~30 dimensions in production, you're under-instrumenting. If you can't answer "show me requests from user X that failed in the last hour" in under a minute, you're missing `user.id` or your tool can't query high cardinality -- fix one or the other.

## Caveats

- **PII and secrets.** `user.email`, request bodies, URLs with tokens, `db.query.text` with literals, and auth/cookie headers are dangerous. Sanitize at instrumentation time, before export. Capture `http.request.header.<key>` only via explicit allowlist; redact signing keys (`AWSAccessKeyId`, `Signature`, `sig`) from `url.query`/`url.full`.
- **Events, not metric labels.** Everything here belongs on spans/events. Putting `user.id` on a Prometheus label causes a cardinality explosion that wide-event stores handle natively but metric stores do not.
- **Don't aggregate at write time.** Wide events derive their power from being raw; never bucket or pre-aggregate before storage. If your bill is dominated by repetitive metadata, sample harder instead of stripping attributes -- and record `sample_rate` per event.
