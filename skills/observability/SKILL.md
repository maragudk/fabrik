---
name: observability
description: Guide for instrumenting and operating observable software systems, distilled from "Observability Engineering" (2nd ed). Use this skill whenever the user is adding or reviewing telemetry, instrumenting code with OpenTelemetry, working with traces/spans/metrics/logs/structured events, debugging production behavior, designing SLOs or alerts, setting up sampling or telemetry pipelines, choosing observability storage, or making code observable for humans or AI agents -- even if they don't say the word "observability". Triggers include "add tracing", "instrument this", "OTel/OpenTelemetry", "why is this slow in prod", "set up an SLO", "alert fatigue", "high cardinality", "structured logging", "wide events", and observability for LLM/agent applications.
license: MIT
---

# Observability Engineering

## Overview

This skill distills the practices in *Observability Engineering, 2nd Edition* (Majors, Fong-Jones, Miranda, Parker; O'Reilly) into actionable guidance. The aim is not to summarize the book but to help you instrument code, debug production, and design reliability mechanisms well.

The throughline: **observability is the ability to understand any state your system can reach -- including ones you have never seen before -- by interrogating its outputs, without shipping new code to capture them first.** In the AI era the bottleneck is no longer writing code; it is validating and understanding the code you (or an agent) just shipped. Observability is the feedback loop that closes that gap.

## When to use this skill

Use it when instrumenting code, reviewing someone's telemetry, debugging a production problem from first principles, designing SLOs/alerts, configuring sampling or pipelines, choosing where to store telemetry, or making a system legible to AI agents. For a one-line "add a log here", you don't need the skill; for anything that shapes *what data exists* or *how you'll answer questions later*, you do.

## The core mental model

- **Observability is a property of dependable software, not a product you buy.** It sits alongside reliability and availability. You can't recover state you never emitted -- if the information wasn't captured, it's gone forever. So the design question is always "what will I need to ask later?"
- **Monitoring answers known-unknowns; observability answers unknown-unknowns.** Threshold dashboards tell you *that* something is wrong and roughly where. They cannot tell you *why* a novel, multi-causal failure happened. Distributed systems fail in a zoo of partial-degradation states, so the rare "inexplicably slow, no smoking gun" case is now the common one.
- **The litmus test:** can *any* engineer, regardless of seniority, diagnose a complex issue purely by interrogating emitted data? If it needs institutional intuition held in a few senior heads, your observability is low.
- **Systems are sociotechnical.** The humans operating the system are part of it. Diagnosis must be teachable and transferable, not folklore.
- **Only production is production.** Tests prove theory; production proves reality. You are not done building until you have observed your change working in production. Test in prod, or live a lie.

## The foundational practice: wide structured events

Everything else rests on this. Get it right and the rest follows; get it wrong and no tool will save you.

- **Emit one wide, structured event per unit of work.** Flat key-value pairs (think a JSON object with no nesting, mapping to a DB row). Capture inputs, discovered context, conditions, and outcomes -- ideally *hundreds* of attributes, not a dozen. A well-instrumented request answers "the /checkout route is slow because auth takes 10s for mobile clients on build v3.2.8", not just "something is broken".
- **Metrics, logs, and traces are not different datatypes -- that split is a historical artifact.** Capture one context-rich representation and derive metrics, logs, and traces from it on demand. A trace is just interrelated structured logs sharing a trace ID plus hierarchy (five fields per span: trace ID, span ID, parent ID, timestamp, duration).
- **High cardinality is a superpower, not a problem.** Capture identifying fields freely: user ID, request/trace ID, build ID, commit hash, container ID, query fingerprint. These are exactly what let you find one specific request later.
- **High dimensionality compounds combinatorially.** More fields means exponentially more queryable combinations; the relationships *between* fields are the value. Adding a 30th attribute is more powerful than the first 29 combined.
- **Pre-aggregation is a one-way trip.** Aggregating at write time (into metrics, into rolled-up counters) permanently destroys the ability to ask questions you didn't anticipate. Store raw events; aggregate at *read* time. You can always compute P99-by-region-by-build later if you kept the events; you can never un-average a metric.
- **The shape of the data you collect constrains the questions you can ask.** Pre-deciding the schema, the indexes, or which metrics to emit pre-decides the investigation -- you'll only ever find what you expected.

**Two telemetry models, and when each is right:**
- *Three pillars* (siloed metrics/logs/traces): right for **infrastructure and third-party code you don't control** -- take whatever it emits, store it cheaply. Built for the operational loop. Destroys cross-signal relationships, forces manual correlation.
- *Unified storage* (wide events in one columnar store): right for **code your team owns** -- your differentiating product. Built for the deploy-observe-learn loop. Rule of thumb: **router -> pillars; billing service -> unified.** Telemetry choices for your own code are *product decisions*, not infra defaults.

## Instrumenting with OpenTelemetry

OTel is the vendor-neutral standard for creating, transmitting, and naming telemetry. The payoff is separation of concerns: instrument once, route anywhere, swap backends via config without touching app code. Generating telemetry is easy; generating *useful* telemetry is the hard part -- instrumentation is sculpting, deciding what to keep.

- **Use automatic and custom instrumentation together.** Auto-instrumentation (HTTP, DB, outbound calls) is the skeleton -- broad coverage for near-zero effort, but only understands lowest-common-denominator plumbing. Custom instrumentation is the muscle: domain operations and domain failures ("insufficient inventory", "coupon expired", "user not in experiment group"). Lasting value accrues in the custom layer.
- **OTel is trace-first; context is the glue.** Any metric, log, or event emitted inside an active context can be correlated back to a specific request. In the Go SDK, context propagation is **explicit** -- thread `context.Context` through your call chain; it does not happen by magic the way thread-locals do in Ruby/Python.
- **Create a span only if it is both interesting and aggregable** -- it meaningfully affects latency/failure *and* grouping by it yields useful trends. Yes: HTTP handlers, DB queries, external calls, cache lookups, queue publish/consume, business transactions. No: getters/setters, pure-CPU helpers, loop iterations (unbounded cardinality), orchestration that just sums children.
- **Prefer wide events over deep span trees.** Wrapping everything in its own span is the #1 beginner mistake -- spans give per-request waterfalls but are painful to query *across* requests (they force joins). Fold detail into attributes on the wide event; a little duplication is worth fast iterative querying during an incident.
- **Own your auto-instrumentation.** It over-produces by default. Drop or sample noisy instrumentation, and replace fine-grained spans with custom spans that summarize small work into parent-span attributes.
- **Naming and schema discipline:** descriptive dot-namespaced snake_case names; no IDs or variable route segments in span names (`/users/{user.id}`, move the ID to an attribute); units and type in metadata, not the name. Drive consistency with a checked-in schema (e.g. OTel Weaver) -- one canonical key per concept. Conflicting attribute keys cripple incident response and mislead AI agents.
- **PII defense in depth:** redact/allowlist via SDK and Collector processors; use stable hashes for identifiers you need to correlate but not expose; apply residency/retention rules early in the pipeline.

For the full what-to-capture catalog, per-architecture patterns (streaming, async fan-out, long-running jobs, serverless, eBPF), span-link usage, and ontology design, read `references/instrumentation.md`.

## Analysis: debug from first principles

Collecting good telemetry is half the job; how you analyze it is the other half. Stop debugging from known conditions (intuition, "what normal looks like", flipping through dashboards) -- that doesn't scale, doesn't transfer, and fails on novel multi-causal incidents.

**The core analysis loop** (hypothesis-driven, scientific, teachable):
1. Start from the signal -- what did the alert/customer/anomaly actually tell you?
2. Verify it's real -- is there a notable change in some curve?
3. Isolate what's different *inside* the anomaly vs the baseline -- examine outlier rows, group by useful fields (status code, build, region), filter to expose outliers.
4. Know enough? If yes, done. If no, filter to narrow and return to step 3.

It needs no prior mental model of every subsystem -- it brute-forces across all dimensions to find which ones correlate with the anomaly. **Automate the brute force:** compute each dimension's distribution inside vs outside the anomaly, diff, and rank by largest difference (the "BubbleUp" pattern). This only works if you have wide events to slice; metrics lack the dimensionality.

**Anti-patterns:** exhaustive runbooks and "every known root cause" docs (they go stale; wrong docs are worse than none -- keep only ownership, escalation, dependencies, and a few good entry queries; instrumentation is the best living documentation). Confirmation bias (guessing a cause, then hunting for supporting evidence). Confusing correlation with causation while brute-forcing.

## Observability-driven development (ODD)

ODD complements TDD: **TDD verifies correctness against a spec; ODD verifies behavior against reality.** Tests pass in a controlled world with variability removed; production *is* variability. So ship every feature together with the instrumentation needed to measure its impact and debug it.

- **The PR gate:** never merge without answering *"How will I know if this change is working as intended?"* New functionality is a new failure source -- instrument it as you write, while you still remember intent.
- **Put engineers on call for their own code,** at least for ~30-60 min post-deploy. This is feedback, not punishment; you can't build good instincts while insulated from your errors.
- **Observability narrows the search space; a debugger zooms in.** It operates on the order of systems, not functions -- which component, dependency, segment, build, AZ, or hop originated the latency. Once you've isolated location and conditions, copy the failing request's context into a local instance and switch to a debugger/profiler. Don't use observability as verbose line-level logging.
- **Validate against real traffic:** feature-flag to a subset, or route select requests to the new path, and compare cohorts (new build vs old, by endpoint, by tier). This catches a regression in 1% of traffic before aggregates move.
- **Decouple deploys from releases with feature flags.** Deploy constantly, one changeset at a time -- batching N people's changes is N times the rollback pain. Flags also gate unfinished code, target cohorts, and kill features instantly without a redeploy.
- **Aggregates conceal sins.** "99.99% before and after" tells you nothing about the change you just shipped. Be precise: "compaction up 5%, disk down 30% for this build_id + flag combo on the 10% canary vs the 90% baseline; return-code distribution unchanged."

## SLOs and alerting

**Alert on symptoms of user pain, not on causes.** Threshold alerts (CPU > 80%) measure what's easy, not what users feel -- they breed alert fatigue and "normalization of deviance" until the one real alert drowns. They also only cover known-unknowns, while distributed systems are dominated by unknown-unknowns, and self-healing systems (autoscale, circuit breakers) trip them for conditions that resolve themselves.

**The two-part test for a helpful alert:** (1) it's a reliable indicator of degraded user experience, and (2) it's actionable. If it fails either test, delete it.

- **Define SLIs from critical user journeys**, classify each event good/bad, and set SLOs (targets) on them. Start with a handful of journeys, not full coverage. 99.99% (~4.3 min/month) is the usual pragmatic sweet spot for revenue-bearing flows; don't out-SLO your dependencies. Set internal SLOs stricter than external SLAs.
- **Prefer event-based SLIs over time-based.** Time-series forces a "good minute / bad minute" verdict -- if 94% of requests met the SLI, the whole minute is marked bad. Per-event granularity measures partial brownouts (the common modern failure) accurately and buys you response time. Raw events also let you backfill SLIs when criteria change.
- **Alert on error-budget burn, before the budget empties.** Use a trailing sliding window (30 days is typical -- matches customer recency bias and degrades smoothly). Prefer **predictive burn alerts** (extrapolate current burn to forecast exhaustion) over crude threshold-crossing alerts. The lookahead window sets urgency; run several simultaneously and act on whichever fires.

For SLO adoption (it's a sociotechnical problem -- alignment matters more than query-writing), burn-alert math, baseline-window sizing, and acting on alerts, read `references/slos-and-alerting.md`.

## Cost, sampling, pipelines, and storage

At scale, storing 100% of events costs more than it's worth -- most events are near-identical successes. **Sample to keep representative events plus enough metadata to reconstruct traffic shape.** Every sampled event must carry the sample rate in effect, so the backend can weight it back up.

- Match the strategy to traffic: fixed-rate (simple, needs high volume), target-rate (predictable cost), per-key/dynamic (keep all errors, sample successes heavily). Use **head sampling** (decide at trace start from static fields, propagate the decision) for cheap in-process work; **tail sampling** (decide after completion from status/latency) needs an external Collector. Use **consistent sampling** (derive the keep decision from a propagated ID) so whole traces survive together. In Go, reach for `dynsampler-go` or the OTel samplers rather than rolling your own.
- **Telemetry pipelines** (OTel Collector: collect -> normalize/secure -> enrich -> reduce -> route) decouple producers from consumers and turn telemetry from a runaway cost into a reusable asset. Start with the agent + gateway pattern; redact PII before data leaves your environment; the biggest cost lever is *reduce* (filter/dedupe/sample before expensive backends).
- **Storage:** observability data wants a columnar store partitioned by time, computing everything at read time over arbitrary cardinality -- not a TSDB (cardinality explosion) or an over-indexed general DB. Don't over-engineer for small volumes: a single-binary ClickHouse beats a multi-service architecture until scale demands otherwise.

For sampling code patterns, pipeline architecture, and the transferable storage-design lessons (Retriever and ClickHouse), read `references/storage-sampling-pipelines.md`.

## Observability for AI: agents and LLM applications

This is where the 2nd edition's emphasis lands, and it's directly relevant to AI engineering work.

- **Agents are only as good as the context they're given.** A senior engineer carries an implicit mental model (topology, naming chaos, what "normal" looks like) that an agent querying telemetry cold does not have. The biggest differentiator in agent effectiveness is not the model -- it's a maintained, machine-readable **context layer** (service topology, naming map, deploy context, known issues, recent incidents, business criticality).
- **Encode senior intuition into the telemetry,** or it effectively doesn't exist. Consistent semantic attributes and human-readable field descriptions let both humans and agents reason. Agents aren't usually hallucinating -- they're optimized for confidence and reason rationally from incomplete context; the dominant failure mode is *inferring meaning incorrectly* (e.g. reading a calculated `is_slow` column as a feature flag). Fix it with clear descriptions, not more prompting.
- **Instrument LLM applications around a learning flywheel:** production telemetry feeds evaluations, evals inform prompt/harness changes, improvements show up in telemetry. Lean on OTel GenAI semantic conventions; derive cost at query time from model + token counts; capture user-feedback signals (thumbs, retries); use SLOs (not threshold alerts) for flaky providers; and make it easy to promote a production trace into an eval. Sometimes a little code beats more prompting (programmatically fixing malformed JSON dropped Honeycomb's error rate from 25% to 14% before prompt work took it under 1%).
- **Validate non-deterministic output with deterministic guardrails.** Where correctness is definable, treat invariants as a semantic firewall: simulate the AI's proposed action through a deterministic engine and reject anything that breaks an invariant. Emit the same structured payload in CI and production so the assertion that blocks a PR is the identical query that fires an incident.

For the full agent context layer, LLM telemetry design, the eval flywheel, and ontology/invariant patterns, read `references/ai-llm-and-agents.md`.

## Strategy, decisions, and organizational change

Most of the back third of the book is about the organizational side -- valuable when you're advising on observability strategy, not just writing instrumentation.

- **Build vs buy is an economic bet on engineering cycles, not a technical choice.** Buy commodity (logging, identity, the observability platform itself); build only what's a genuine *revenue/market-share* differentiator. The winning default: **buy the platform, build the integration layer** (wrappers, naming standards, abstractions) owned by an observability team. Default to OTel + exporters so instrumentation survives a vendor migration. "Free" in-house stacks rarely are.
- **An observability team's job is governing the shared language of telemetry** (semantic conventions, schemas, paved paths), not handing out dashboards. The right way and the fastest way must be the same way -- embed OTel into the service framework so adoption is a library bump.
- **Treat observability as an investment, not a cost center** -- it inherits the value of the code it observes. Developer-learning observability should report to engineering leadership, not IT/ops. Lead the case with capability and risk/burden reduction, not consolidation or cost (those framings get cut).

For build/buy frameworks, vendor partnership and procurement tactics, observability-team practices, the business case, systems-thinking lens, and the organizational shift, read `references/strategy-and-org.md`.

## A few rules of thumb to carry around

- Design data for how you'll *query* it, not how the code is structured.
- If you can't answer a question you didn't anticipate without deploying, that's monitoring, not observability.
- One source of truth or many -- you can't have both. Prefer one for code you own.
- A failed request with no error context flags weak error handling.
- The inability to regenerate or explain your code is a sign you don't understand it; observability is how you build that understanding.
