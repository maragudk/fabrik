# SLOs and alerting

How to alert on user pain instead of causes, using service-level objectives backed by event-based indicators and predictive burn alerts.

## Contents

- [Why threshold alerts fail](#why-threshold-alerts-fail)
- [What makes an alert worth keeping](#what-makes-an-alert-worth-keeping)
- [SLO, SLI, error budget](#slo-sli-error-budget)
- [Defining a good event-based SLI](#defining-a-good-event-based-sli)
- [Burn alerts](#burn-alerts)
- [Why event data beats time-series for SLOs](#why-event-data-beats-time-series-for-slos)

## Why threshold alerts fail

Traditional monitoring alerts on what's easy to measure -- CPU > 80%, memory < 10%, disk nearly full. These are *potential-cause* signals: high CPU could be a backup job, GC, or a real problem. They produce many false positives, so teams learn to silence them -- **normalization of deviance** (the term comes from the Challenger disaster: once routinely ignoring an alarm feels normal, missing a real one no longer feels wrong). Post-incident reviews then add *more* alerts, compounding the noise.

Threshold checks also only catch **known-unknowns** -- failures you already anticipated. You can't add a static check ahead of time for a part that breaks in a way nobody predicted.

## What makes an alert worth keeping

Delete any alert that fails *both* of these:

1. **It's a reliable indicator of degraded user experience** -- it reflects real customer pain, not an internal state.
2. **It's actionable** -- there's a systematic way to investigate and respond, not rote automation and not divination.

Auto-remediated failures (autoscaling, failover, rollback) should *not* page -- debug them in business hours. Paging is only for emergencies that can't wait.

## SLO, SLI, error budget

- **SLO (Service-Level Objective):** an internal target for service health, defined around critical end-user journeys, not system metrics. Set it stricter than any external SLA so it warns you *before* customers are truly harmed.
- **SLI (Service-Level Indicator):** the measurement that classifies system state as good or bad. Two kinds:
  - *Time-based:* "p99 latency < 300 ms over each 5-min window."
  - *Event-based:* "proportion of events under 300 ms over a rolling window." **Prefer event-based** -- more reliable and granular, because data isn't pre-aggregated into time buckets.
- **Error budget:** the amount of "bad" the SLO target permits. A 99% SLO over a ~43,800-unit month allows 438 failed units. Each failure spends budget; enough burn triggers an alert.

## Defining a good event-based SLI

Make it qualify success on the *user's* terms, not just the HTTP status. Example -- "user loads /home and sees a result quickly":

- Match events with request path `/home`.
- If `duration_ms < 100` **and** served successfully -> OK.
- If `duration_ms > 100` -> error, *even if it returned a 200*.

The point: an SLI should fail when the user had a bad time, regardless of whether the system *thinks* it succeeded.

## Burn alerts

The question a burn alert answers: *are we on track to exhaust the error budget before the SLO window closes?*

### Use a sliding window

Always frame time as a **sliding window** (e.g. trailing 30 days), not a fixed calendar window. Fixed windows reset abruptly, mismatch customer memory (recency bias doesn't reset on the 1st), and leave too little post-reset data to forecast. 7-14 days is too short (misses customer/planning cycles); 90 days is too long (you could burn 90% in a day and still pass).

### Predict, don't just threshold

A zero-level alert (budget exhausted) and a static-threshold alert (e.g. trip at 30% remaining) are crude -- the threshold just moves the goalpost and freezes feature work while you wait to recover. Better: **predictive burn alerts** that forecast whether the *current rate* exhausts the budget within a lookahead window.

- **Lookahead window:** how far ahead you forecast. Tune urgency to it -- a trajectory hitting 99.88% in a month is a next-business-day fix; one hitting 98% in an hour pages on-call now.
- **Baseline (lookback) window:** how much recent data feeds the forecast. Keep it the same order of magnitude as the lookahead. Heuristic: **a baseline reliably extrapolates forward by about 4x** (without seasonality compensation). So a 24-hour alarm uses the last 6 hours; a 4-hour alarm uses the last 1 hour. Too-short baselines flap on blips; too-long baselines react too slowly.

### Extrapolate proportionally

Linear extrapolation (multiply baseline failures by the factor) ignores traffic fluctuation. **Proportional extrapolation** is better: apply the baseline *failure rate* to expected traffic. Example -- 25 of 50 units fail in 6h = 50% rate; applied to ~1,440 units/24h = 720 failures, well over a 438 budget, so the budget burns in ~half a day -> page now.

### Run several, act on whichever fires first

Set **multiple burn alerts at different lookahead sizes** and act on whichever trips. A 2-hour projection can fire while a 1-day one doesn't, because they use different baselines. Acting on the short one can avert the long one; the long one supports sprint-level prioritization. When one fires, first diagnose the burn *pattern* -- gradual/steady (often normal), bursty, or one large incident -- and zoom out to a cumulative view to gauge urgency.

## Why event data beats time-series for SLOs

Use **event-based** (per-request) data, not time-series (per-time-slice). Time-series forces good-minute/bad-minute aggregation: if 94% of requests pass in a minute, the whole minute is marked "bad," burning ~25% of a four-nines budget at once -- and you must wait for the minute to *end* to know. Event data subtracts only the actual 6% of failed requests.

Modern systems suffer partial **brownouts**, not full blackouts, so request-level granularity is far more accurate, buys hours more response time, and tells you *which* users or services failed -- which is exactly what you need to start debugging.
