# Wide event attribute catalog

Companion to `instrumentation.md`'s "What to capture on a wide event". That section names the categories; this file lists concrete attributes per category, with the question each one answers. Distilled from chapter 6 of *Observability Engineering, 2nd ed.* (the chapter by Jeremy Morrell); rewritten and condensed here, and deliberately not exhaustive -- use it as a checklist and inspiration, not a schema.

Two framing rules:

- A well-instrumented service emits **hundreds** of attributes per event, not a dozen. Every attribute is a dimension you can group or filter by later without a join.
- Auto-instrumentation supplies some of these (HTTP basics, sometimes routes). Always review what it actually captures, find the gaps, and fill them in yourself. The difference between "something is slow" and "/checkout is slow because auth takes 10s for mobile clients on v3.2.8" is a handful of attributes you added by hand.

## Service and code context

Turns "is something broken?" into "we know which thing, where, who owns it, and what changed."

**Service metadata** -- who owns this and where does it run:

| Attribute | Example | Answers |
|---|---|---|
| `service.name` | `checkout` | Which service is this? |
| `service.environment` | `production`, `staging` | Which environment? |
| `service.team` | `payments` | Who to page during an incident |
| `service.slack_channel` | `#payments` | Where to reach the owners |

Ownership attributes go stale under re-orgs; if you can, derive them from a service catalog. With just these you can answer "how many production services does each team run?" with one GROUP BY.

**Infrastructure** -- is the load appropriate for the machine, without opening another tool:

| Attribute | Example | Answers |
|---|---|---|
| `instance.id` | a UUID | Which exact instance served this? |
| `instance.memory_mb` | `12336` | How much RAM does it have? |
| `instance.cpu_count` | `8` | How many cores? |
| `instance.type` | `m6i.xlarge` | Which vendor instance type? |

**Orchestration** -- follow the OTel Kubernetes semantic conventions: `container.id`, `container.name`, `k8s.cluster.name`, `k8s.pod.name`, `cloud.region`, `cloud.availability_zone`. On a PaaS, extract the platform equivalents instead (for Heroku: dyno name, type, index, size, private space, region) -- and split composite values like `web.1` into separate type and index attributes so each is queryable on its own.

## Build information

"Did something just deploy?" is the first incident question. Answer it from telemetry instead of the deploy tool. Threading build data from CI to runtime takes some glue code; it pays for itself in the first incident.

| Attribute | Example | Answers |
|---|---|---|
| `service.version` | `v123` or a git hash | Which build served this request? |
| `service.build.id` | build-system ID | Audit trail back to the exact build |
| `service.build.git_hash` | full SHA | Exactly which code was running |
| `service.build.pull_request_url` | PR link | What change triggered this deploy |
| `service.build.diff_url` | compare link | What changed vs the previous deploy |
| `service.build.deployment.at` | RFC 3339 timestamp | When the deploy started |
| `service.build.deployment.user` | email | Who kicked it off |
| `service.build.deployment.trigger` | `merge-to-main`, `manual`, `config-change` | Config change vs auto deploy vs manual |
| `service.build.deployment.age_minutes` | `7` | Did something *just* deploy? |

Grouping errors by `service.version` during a rollout tells you immediately whether a 500 spike comes from the new build starting or the old build shutting down uncleanly -- without the version dimension those are indistinguishable.

## Feature flags

Record the value of each relevant flag on every request: `feature_flag.auth_v2 = true`, `feature_flag.double_write_to_new_db = false`. This is what lets you compare the new code path against its control group ("what errors do users in the new auth flow hit, versus everyone else?") as you ramp a rollout or run a migration.

## Versions of important things

Runtime, framework, and datastore versions: `go.version`, `rails.version`, `postgres.version`, and whatever else is core to your stack. Two recurring uses: a CVE drops and you need "which services run the vulnerable version?" in one query, and a resource regression ("memory looks higher -- didn't we bump Go recently?") correlates instantly when you can group a memory heatmap by runtime version.

## Request and execution flow

Turns one event into a narrative: what was called, how long each step took, where it failed.

**HTTP basics** -- mostly auto-instrumented, but verify and extend:

| Attribute | Example | Notes |
|---|---|---|
| `server.address` | `example.com` | Receiving host |
| `url.path` / `url.scheme` / `url.query` | `/checkout`, `https`, `ref=…` | Raw URL parts |
| `http.request.id` | platform request ID | Correlate with CDN/load-balancer logs |
| `http.request.method` | `POST` | |
| `http.request.body_size` / `http.response.body_size` | bytes | Outlier payloads are debugging gold -- a response-size heatmap surfaces them instantly |
| `http.response.status_code` | `500` | |
| `http.request.header.<name>` / `http.response.header.<name>` | `content-type` | Any header that matters to your service |

**User agent** -- parse it into structure at write time; never regex `user_agent.original` at query time: `user_agent.device` (`phone`/`computer`), `user_agent.os`, `user_agent.browser`, `user_agent.browser_version`. If your org uses custom user agents or headers, extract those too: `user_agent.service` + `user_agent.service_version` for service-to-service calls, `user_agent.app` + `user_agent.app_version` for mobile clients.

**Route** -- the single most useful HTTP attribute, plus its parts:

| Attribute | Example |
|---|---|
| `http.route` | `/team/{team_id}/user/{user_id}` (the pattern, never the raw path) |
| `http.route.param.<name>` | `http.route.param.team_id = 14739` |
| `http.route.query.<name>` | `http.route.query.sort_dir = asc` |

A latency spike grouped by `http.route` becomes "only POST /checkout and POST /signup are slow" -- then group by version to check whether a deploy caused it.

**Inline timings** -- pick the few segments that matter and put their durations on the wide event: `auth.duration_ms`, `payload_parse.duration_ms`, one per core workload. Child spans could carry the same data, but querying them alongside the parent's attributes forces a self-join on trace ID; a flat attribute makes "P99 parse time by user tier and region" a one-liner and feeds anomaly tools like BubbleUp. Accept the slight duplication -- design data for how you query it, especially mid-incident.

**Async/dependency summaries** -- roll per-dependency work up onto the parent event as count + cumulative duration pairs: `stats.http_requests_count` / `stats.http_requests_duration_ms`, `stats.postgres_query_count` / `stats.postgres_query_duration_ms`, same pattern for Redis, and for each external vendor API. A heatmap of query count per request exposes N+1 patterns and outlier requests that hammer the database; the async work still gets its own spans for waterfalls.

**Errors** -- on failure, attach everything you know:

| Attribute | Example | Notes |
|---|---|---|
| `error` | `true` | The canonical "did this request fail" field |
| `exception.message` | the message | |
| `exception.type` | `IOError` | Programmatic type |
| `exception.stacktrace` | trace text | Pinpoints the throw site |
| `exception.expected` | `true` | Filter out failures you can't prevent and don't care about (bots probing dead URLs) |
| `exception.slug` | `err-stripe-call-failed-exhausted-retries` | See below |

The slug is the high-leverage one: tag every throw site with a unique **static string** (enforce no-dynamic-strings with a lint rule). It's greppable -- straight from a dashboard spike to the line of code -- and a clean low-cardinality GROUP BY. And the gaps are informative: `error = true AND exception.slug = NULL` is a ready-made list of requests failing in ways you never anticipated, i.e. where your error handling needs work.

## User and business context

The most valuable category, and the one no SDK can derive -- only you know your user model. It turns debugging into prioritization: "weird edge case" vs "revenue-critical path broken for enterprise customers."

| Attribute | Example | Answers |
|---|---|---|
| `user.id` | `2147483647` | Exactly who is affected (mind PII policy if IDs are emails and the backend is a vendor) |
| `user.type` | `free`, `enterprise`, `vip` | Is this segment business-critical? Single accounts can be 10%+ of revenue with usage patterns nothing like the median user -- you must be able to isolate their traffic |
| `user.auth_method` | `jwt`, `sso-github` | Which auth path was taken |
| `user.team.id` / `user.org.id` | IDs or slugs | Tenant-scoped bugs; lets account managers proactively contact affected enterprise orgs |
| `user.creation_timestamp` | epoch seconds | New-user bug or long-time-user-with-lots-of-data bug? |
| `user.assumed` / `user.assumed_by` | `true` / engineer email | Impersonation tracking -- operationally useful and usually required for security audits |

"Which users are affected?" is among the first questions in any incident and famously hard to answer; with these attributes it's a GROUP BY.

**Rate limits** -- most tools can't show you *who* is being rate limited; these attributes fix that: `ratelimit.limit`, `ratelimit.remaining`, `ratelimit.used`, `ratelimit.reset_at` (adapt to your algorithm's parameters -- capture whatever you'd want in front of you while an angry customer asks why they're throttled). Filtering to one user and grouping by route shows exactly what exhausted their quota -- a buggy automation, or leaked credentials being abused.

**Caching** -- one hit/miss boolean per cacheable code path, e.g. `cache.session_info`, `cache.feature_flags`.

**Localization** -- a frequent bug source: `localization.language_dir` (`rtl`/`ltr`), `localization.country` (the user's chosen country -- people travel, so this differs from geo-IP), `localization.currency`.

## Operational information

**Uptime** -- `uptime_sec` (seconds since process start) plus `uptime_sec_log_10`. The log form keeps a 3-day-old instance and a 40-second-old instance readable on the same graph, which makes crash loops jump out: every instance serves traffic for a few seconds, dies, restarts. Catches reboot-triggered bugs and slow memory leaks too. Follow up by grouping by `service.version` to check whether a release started the looping.

**In-process metrics snapshot** -- sample runtime stats every ~10s, cache them, stamp them onto every event emitted in that window: `metrics.memory_mb`, `metrics.cpu_load`, `metrics.gc_count`, `metrics.gc_pause_time_ms`, `metrics.goroutines_count`, `metrics.event_loop_latency_ms` (Node). For cumulative-or-delta values, pick one and document it. This answers "are these requests slow because we're out of memory/CPU?" without leaving the tool. Caveat: it's not mathematically rigorous -- you only get samples when traffic flows -- so use heatmaps for debugging signal and keep real metrics for alerting.

**The `main` convention** -- tag the one span that wraps the whole request or job with `main = true`. Wide events coexist with other logs and child spans; this flag filters to exactly one event per unit of work. Grouping `main` spans by name is a fast map of what work an unfamiliar service does. It also keeps math honest: `http.response.status_code` appears on outbound-subrequest child spans too, so an error-rate query without `main = true` counts the wrong things.

## Attributes specific to your application

The highest-value data, and the part nobody can automate for you. Whatever your domain's load-bearing nouns are, capture them: the storage path an upload landed in (`asset_upload.s3_bucket_path`), the transaction ID a vendor handed back (`email_vendor.transaction_id` -- you'll want it when you open a support ticket with them), which of a small set of integration types a request used (`vcs_integration.vendor = github|gitlab|bitbucket` -- when one provider has an outage, the 2% failure spike explains itself), the queue length observed at submission time (`process_submission.queue_length`). If a fact would help you debug, it belongs on the event.
