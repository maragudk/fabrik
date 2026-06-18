# Instrumentation deep dive

Companion to the "Instrumenting with OpenTelemetry" section of SKILL.md. Covers the full what-to-capture catalog, per-architecture span patterns, naming/schema discipline, and ontology design.

## Contents
- What to capture on a wide event
- Span-level techniques
- Architectural patterns beyond request/response
- Layering signals without duplicating
- Naming and schema
- Using AI agents to instrument
- Ontologies as a shared language

## What to capture on a wide event

Aim for hundreds of attributes. Categories (not exhaustive):

- **Service / code context:** `service.name`, environment, owning team and Slack channel; instance specs (memory, CPU, type); orchestration (k8s pod/cluster, cloud region/AZ).
- **Build info:** `service.version`, git hash, PR/diff URL, deploy timestamp, who deployed, deploy trigger (merge/manual/config-change), deployment age. Answers the first incident question -- "did something just deploy?"
- **Feature flags:** per-request flag values, so you can compare a new code path against its control group.
- **Versions** of runtime, frameworks, datastores -- instantly answers "which services run the vulnerable library version?"
- **Request flow:** HTTP method/path/status/sizes, specific headers, parsed user-agent (device/OS/browser -- parse upfront, don't regex later), `http.route` (the pattern, not the raw path) plus extracted route and query params.
- **User / business context** (the most valuable -- no SDK can auto-derive it): `user.id`, `user.type` (free/enterprise/vip), org/team, auth method, account age, assumed-identity tracking. This turns debugging into prioritization (revenue-critical vs edge case).
- **Operational:** rate-limit budget, cache hit/miss per path, localization, `uptime_sec` (plus a `log10` variant to spot crash loops), and in-process metrics (memory, CPU, GC, goroutines) snapshotted every ~10s and tagged onto each event.
- **Domain-specific attributes** -- the highest-value data, the stuff only you can know.

## Span-level techniques

- **Error slugs:** tag each throw site with a unique, greppable, *static-string* `exception.slug`. Lets you jump from a dashboard spike straight to the line of code, and serves as a low-cardinality GROUP BY. Enforce static strings with a lint rule. A failed request with no slug flags weak error handling.
- **The `main` convention:** tag the single request/job-wrapping span with `main=true` so you can filter out child-span noise. (Without it, `http.response.status_code` appears on subrequest spans too and inflates error rates.)
- **Inline timings over spans:** put a few important segment durations (`auth.duration_ms`, etc.) directly on the wide event rather than minting child spans.
- **Async summaries:** roll up per-dependency counts and durations (`stats.postgres_query_count`, etc.) onto the parent event.

## Architectural patterns beyond request/response

- **Streaming / queues:** propagate context in the message envelope; tie producer and `messaging.process` spans with **span links** (not parent-child). Carry a correlation ID through the pipeline. Drive alerting from per-stage metrics (`failed_total`/`processed_total` ratios, dwell-time histograms) with exemplars linking outliers back to traces.
- **Async fan-out / fan-in:** root span = the entry request; link to child tasks; add a final summarization span. Alert at the entry point or on specific tasks.
- **Long-running jobs:** model each stage as its **own trace** linked by correlation IDs -- avoid the million-children trace. Don't update or flush spans over time (most stores reject span updates); use metrics/logs for intermediate status, and emit a wide summary event at completion as a safety net.
- **Serverless:** prefer custom over auto-instrumentation; ideally one rich span per invocation to save cold-start and memory cost. Consider stateless Lambda plus a stateful Collector for assembly.
- **eBPF (e.g. OBI):** kernel-level, zero in-process overhead, toggleable without restart. Use as a gap-filler for uninstrumentable/legacy services and service maps -- not a replacement for real instrumentation.

## Layering signals without duplicating

Three-question test for which signal to reach for:
- Need causality + full-request context? -> **traces**.
- Need cheap long-term storage / fast alerting? -> **metrics**.
- Rare or audit-sensitive? -> **logs/events**.

Common combo: a span plus a RED histogram per HTTP request (head-sample the traces, keep the histograms for last-ditch alerting). Generate metrics *from* spans via the Collector rather than re-instrumenting -- but note span-derived metrics break under head sampling.

## Naming and schema

- Names: descriptive, dot-notation, snake_case. No IDs or variable route parts in names (`/users/profile/{user.id}` -> move the ID to an attribute). Put units and type in metadata, not the name (`http.server.request.duration`).
- Drive consistency with a **schema file** (e.g. OTel Weaver) checked into source control -- one canonical key per concept. Conflicting attribute keys cripple incident response and mislead AI agents.
- **PII defense in depth:** stable hashes (reversible via an internal API) for identifiers you must correlate; allowlist/filter via SDK plus Collector processors; attach units as attributes.

## Using AI agents to instrument

- The value is the **strategy** (what and how to instrument), not typing span calls. Use planning mode (produce a reviewable spec/schema, no code) then execution mode in small reviewable chunks.
- Agents imitate existing repo patterns, good or bad -- give explicit patterns and rules, checked into version control like shared software.
- Prefer "automate the automation": have the agent write scripts to apply changes. Add **telemetry tests** that diff before/after (or old APM vs new OTel). Work file-by-file, commit often, throw away disposable tooling.
- Put observability guidance in agent config under one header; be detailed and direct, and map attribute sources explicitly (e.g. "each route handler must set `app.customer.id`/`app.customer.plan_type` from request-context `customerId`/`plan`"). Use a centralized helper library of attribute constants so agents reuse them instead of inventing new keys.

## Ontologies as a shared language

Infrastructure can be 100% green while the system is broken, because the failure is *semantic*, not infrastructural. The cause is disjoint language ("availability" means uptime to a dev, an accurate bill to the business). An **ontology** is a structured map of a domain's core entities, their relationships, and the invariants that constrain valid behavior; it becomes operational through semantic conventions every service agrees to emit.

Design a minimal ontology:
1. **Define the nouns (entities).** Keep it minimal.
2. **Define the invariants (rules)** -- mathematical truths that must always hold (coverage, arithmetic consistency, determinism). A violation means a broken system even if no exception is thrown.
3. **Schematize intent.** Force an LLM to fill a structured schema (discrete fields) rather than act freely, so you can validate the *why*, not just the *what*.

Treat invariants as a **semantic firewall**: simulate any proposed action through the deterministic engine and reject plans that break an invariant. Emit the exact same structured payload in CI and in production, so the assertion that blocks a PR merge is the identical query that fires a production incident. See `ai-llm-and-agents.md` for the AI-sandwich architecture this enables.
