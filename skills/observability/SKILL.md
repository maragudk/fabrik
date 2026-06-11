---
name: observability
description: Guide for applying observability best practices when writing and instrumenting code -- wide structured events, OpenTelemetry instrumentation, distributed tracing, SLO-based alerting, sampling, and debugging from first principles. Use this skill whenever adding logging, metrics, traces, or telemetry to code; instrumenting a service, handler, or job; wiring up OpenTelemetry or spans; deciding what context to capture for production debugging; defining SLOs, SLIs, error budgets, or alerts; or reviewing whether a change will be debuggable once it ships -- even if the user never says the word "observability".
license: MIT
---

# Observability

## Overview

Observability is the ability to understand any state your system can get into -- including novel, never-before-seen failures -- by asking arbitrary questions of your telemetry, without shipping new code to investigate. The litmus test: can you debug a brand-new problem you never predicted, iteratively, in seconds?

This matters because modern systems (microservices, managed dependencies, ephemeral infrastructure, many network hops per request) fail in genuinely novel ways. The hard question shifted from *why is this code wrong* to *where in the system is the problem*. Traditional monitoring only catches failures you predicted and set thresholds for ("known-unknowns"); observability is what lets you debug the ones nobody anticipated ("unknown-unknowns").

This skill is about the engineering side: how to instrument code so it's debuggable in production, and how to alert on what actually matters. The cultural and organizational side (rolling it out across a team, build-vs-buy) lives in `references/adoption.md`.

## When to Use This Skill

Use it whenever you are:

- Adding logging, metrics, traces, or any telemetry to code
- Instrumenting a service, request handler, background job, or pipeline
- Setting up OpenTelemetry, spans, or context propagation
- Deciding what data to capture so a future incident is debuggable
- Defining SLOs, SLIs, error budgets, or production alerts
- Reviewing a PR and asking "how will we know if this works in production?"

## Core principles

These are the ideas to apply by default. The reference files give the concrete code patterns and deeper rationale.

### 1. Emit wide, structured events -- one per unit of work

The fundamental unit of observability is the **arbitrarily wide structured event**: one record per unit of work (typically one request), carrying many key-value pairs of context.

The pattern: when a request enters, initialize an empty context map; throughout its life, append anything interesting; when it exits or errors, emit the whole thing as one rich event. Mature instrumentation routinely carries **300+ fields per event**. There is no practical limit -- the wider the event, the more questions you can answer later.

Capture data from all three phases:
- **On entry:** request params, headers, build/version, host and container info.
- **During execution:** user ID, session, computed values, every downstream call and its duration, intermediate results.
- **On exit:** total duration, status code, error messages.

Think like a debugger that records every variable's value and every (possibly remote) function call's timing -- then ships that snapshot somewhere queryable.

See `references/attributes.md` for a grouped checklist of what to capture -- identity, tenancy, build/deploy, feature flags, timing rollups, and more -- with OTel semantic convention names.

### 2. Maximize cardinality and dimensionality

These two properties are what make events useful for finding unknown-unknowns:

- **High cardinality** = fields with many possible values: `user_id`, `request_id`, `trace_id`, `shopping_cart_id`, `build_id`, `hostname`. These are the most powerful debugging dimensions because a unique ID is how you find one needle in the haystack. Rule of thumb: you can always bucket high cardinality down to low later, but you can **never** recover cardinality you didn't capture -- so capture it.
- **High dimensionality** = many different fields you can combine in one query. Six dimensions already let you ask "all 502s in the last 30 min on host foo"; hundreds let you isolate "Canadian iOS 11.0.4 users, French language pack, firmware 1.4.101, on shard3 in us-west-1" -- which is how you find what a cluster of outliers have in common.

This is also why **pre-aggregated metrics fall short** for debugging: a metric is one number over a time window with a few low-cardinality tags. It discards per-request context, can't slice by user ID, and forces you to decide what to measure *before* the bug happens. Use events as your primary signal; reach for standalone metrics only when you genuinely need exact, unsampled, process-wide counts.

### 3. Instrument with OpenTelemetry, and instrument as you write the code

Use **OpenTelemetry (OTel)** as the default instrumentation layer. Instrument once against a vendor-neutral API, then send telemetry to any backend. Proprietary agents create lock-in, and re-instrumenting is the most labor-intensive part of switching tools, so portability is worth a lot.

- **Start with auto-instrumentation** for fast time-to-value -- it surfaces the service call graph, HTTP/gRPC/DB calls, and obvious problems like uncached hot queries.
- **Add custom instrumentation** for business context. This is where the real value is: auto-instrumentation is the skeleton; custom attributes are the meat.
- **Instrument alongside the feature, not afterward.** Treat code without instrumentation like code without comments. The guiding question for every change: *"How will I know if this is working as intended once it ships?"*

See `references/instrumentation.md` for OTel concepts, span structure, context propagation, and Go code patterns.

### 4. Traces are wide events stitched together

A trace follows one request across process and network boundaries. Each unit of work is a **span**; spans nest into parent-child relationships and render as a waterfall. Distributed tracing is what makes cascading problems (a slow downstream DB showing up as latency across many upstream services) diagnosable.

The mechanics -- the five required span fields, context propagation via headers, and what custom fields to add -- are in `references/instrumentation.md`.

### 5. Alert on user pain (SLOs), not on causes

Threshold alerts ("CPU > 80%") fire on *potential causes* and produce so many false positives that teams learn to ignore them -- this is normalization of deviance, and it's how real incidents get missed.

Instead, alert on **symptoms of degraded user experience** using **SLOs** backed by **event-based SLIs** and an **error budget**. An alert earns its place only if it's both a reliable indicator of user pain *and* actionable. Auto-remediated events (autoscaling, failover) should not page.

SLO alerts deliberately decouple *what* (users are hurting) from *why* (the cause) -- they tell you to investigate, and observability is what lets you find the cause of even an unknown failure. Rule of thumb: **collect data for everything, but alert only on user-impacting symptoms.**

See `references/slos.md` for defining SLIs, error budgets, and predictive burn alerts.

### 6. Debug from first principles, not intuition

When investigating, resist pattern-matching against past incidents (that knowledge doesn't transfer and locks debugging to the most senior person). Instead use the **core analysis loop**: start from the symptom, verify it's real, find which dimensions distinguish the affected events from the baseline, filter to isolate, and repeat. With wide events this is a methodical, teachable process that works even on failures you've never seen -- the best debugger becomes the most curious engineer, not the longest-tenured.

See `references/adoption.md` for the core analysis loop in detail.

### 7. Sample deliberately at scale

At high volume, keeping every event costs more than it's worth, and most events are near-identical successes. Sampling cuts cost while -- unlike aggregation -- preserving full cardinality on the events you keep.

The two things that bite people:
- **Record the sample rate in each event**, and reweight on read. With variable rates you cannot just multiply by a constant.
- **Make the sampling decision consistently across a trace** (propagate one sampling ID), so you never keep a child span while dropping its parent.

See `references/instrumentation.md` for sampling strategies and code.

## Anti-patterns to flag

- Treating "metrics + logs + traces" (the "three pillars") as the goal. Those are data types; observability is about high cardinality, high dimensionality, and the ability to explore. Don't fragment telemetry into three disconnected stores that force engineers to context-switch.
- Pre-aggregating into metrics as the primary signal, then adding a new custom metric every time a question comes up.
- Many narrow log lines per request instead of one wide event. If you have logs, make them structured (key-value/JSON) and carry a `trace_id`.
- Schemas or fixed field sets that cap event width or reject high-cardinality fields.
- Debugging only in staging. Staging can't reproduce distributed production; instrument production and make it safe to debug there (feature flags, progressive delivery).
- Line-level instrumentation to debug program logic. Observability tells you *where* the problem is (which service, which hop, which users); hand off to a debugger or profiler for *what's* wrong in the code.

## Reference files

- `references/attributes.md` -- a grouped checklist of attributes for wide events (identity, tenancy, build/deploy, errors, timing rollups, feature flags, ...), OTel semconv naming guidance, and staged adoption.
- `references/instrumentation.md` -- OpenTelemetry concepts, structured event construction, span fields and tracing mechanics, context propagation, and sampling, with Go code patterns.
- `references/slos.md` -- SLOs, SLIs (prefer event-based), error budgets, and predictive burn alerts (lookahead/baseline windows).
- `references/adoption.md` -- the core analysis loop, the monitoring-vs-observability boundary (system vs software), build-vs-buy, and rolling observability out across a team.
