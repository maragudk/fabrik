# SLOs and alerting deep dive

Companion to the "SLOs and alerting" section of SKILL.md. Covers SLO adoption as a sociotechnical problem, error-budget mechanics, burn-alert models, and acting on alerts.

## Why threshold alerting fails

- It measures what's easy (CPU, memory) not what users feel, so it generates false alarms and breeds **alert fatigue** and **normalization of deviance** -- teams learn to ignore alerts until the one real alert drowns.
- It only covers **known-unknowns** -- failures you can name ahead of time. Distributed systems are dominated by unknown-unknowns (emergent behavior, cascading retries, brownouts).
- Codifying every past outage into a new alert is an arms race: brittle, unmaintainable, tacit-knowledge-bound.
- Static thresholds are too coarse ("P95 over 5 min" buckets whole intervals), and significance shifts with traffic (10 slow users at 3am is not the same as at peak). Self-healing systems (autoscale, failover, circuit breakers) trip alerts for conditions that resolve themselves -- pure burnout.

## Designing SLIs and SLOs

- **Decouple "what" from "why".** SLO alerts say *something is wrong for users*; observability tooling lets you debug the cause from first principles. SLOs require high observability to be operationally useful.
- **Prefer event-based SLIs over time-based.** Classify each event good/bad/null (e.g. a `/home` request, served successfully, duration < 100ms) rather than bucketing by time window. Finer and more reliable; time-based wrongly marks a whole minute bad if 94% of its requests were fine.
- **Start with a handful of critical user journeys**, not full coverage. A small core set touches most assets without noise.
- **Pick targets by business ROI.** 99.99% (~4.3 min/month) is the usual pragmatic sweet spot for revenue-bearing flows; five-nines rarely justifies its multi-region cost. Set internal SLOs stricter than external SLAs so you catch degradation first. Don't out-SLO your dependencies.

## SLO adoption is sociotechnical

- The hard part is organizational alignment (which journeys matter, what "success" means, tolerable imperfection), not query-writing.
- **Invest in standardized, high-cardinality telemetry first** (e.g. OTel semantic conventions). It pays off on its own and removes friction from the SLO rollout.
- **Pilot SLOs on the most stressed / least-trusted team**, not a high-performing one -- elite teams self-govern and don't need them; SLOs change behavior where there's pain.
- Imperfect-but-improving SLOs beat SLOs confined to elite teams, especially when definitions can be edited retroactively (raw events let you re-derive an SLI when criteria change).
- Use LLMs as **draft generators, not authorities** for SLI/SLO definitions -- they solve the blank-page problem, but their mistakes are subtle (missing filters, wrong error signal, server-vs-internal spans). Validate against real telemetry, review like a PR, and encode standards in version-controlled prompts.

## Error budgets and burn alerts

An **error budget** is the maximum unavailability the business tolerates (99.9% over 30 days = 438 of 43,800 failable requests). The goal is to alert *before* the budget empties, while there's still time to act. Higher SLO targets give less reaction time, so alerts must forecast future burn, not just report current state.

**Frame time as a trailing sliding window** (30 days is typical). Fixed calendar windows reset abruptly and don't match customer recency bias. 7-14 days is too short to match customer memory; 90 days is too long (you could burn 90% in a day and still "pass", and incidents age out too slowly). Sliding windows degrade and recover smoothly.

**Burn-alert models, worst to best:**
- **Threshold-crossing** (alert at 30% remaining): crude -- just relocates the "empty" goalpost; teams freeze features waiting for the budget to climb back. Avoid as the primary mechanism.
- **Relative burn:** compare failures in a short lookback against the proportional allowance, as a multiplier (1x normal, 4x page). Stays aware of expected request rate, so low-traffic windows don't fire spuriously.
- **Predictive burn:** extrapolate current burn to forecast exhaustion. Preferred.

**Predictive burn, rules of thumb:**
- The **lookahead window** sets urgency: on track to hit 99.88% this month -> next business day; on track to hit 98% in an hour -> page now.
- **Baseline should be the same order of magnitude as the lookahead.** A baseline predicts forward by roughly a factor of 4 without seasonality correction -- heuristic: 24h alarm from the last 6h; 4h alarm from the last 1h. Too-small baseline -> flappy false alarms; too-large -> you notice critical failures too late.
- **Proportional extrapolation beats linear** -- scale the observed failure rate against expected traffic volume, since traffic fluctuates by hour/day/week.
- Short-term (ahistorical) alerts use only recent baseline data and are cheap; context-aware (historical) alerts track the whole SLO window and are more expensive (cache aggressively) but let urgency scale with remaining budget.
- Run **multiple lookahead windows simultaneously** and act on whichever fires. Alarms can fire in "illogical" order (a 2h alert but not a 1-day alert) because they use different baselines -- this is expected.

## Acting on alerts

- Diagnose the **burn shape**: gradual/steady (normal), bursty, or a single large incident. The shape hints at the failure type; compare to historical rates to triage urgency.
- **Use event data, not time-series metrics.** Per-request granularity measures partial brownouts accurately (94% good = only 6% of budget burned, not a whole bad minute). Raw events also tell you *who/what* was impacted after an alert fires, and let you backfill SLIs when criteria change.

## The two-part test for any alert

1. It's a reliable indicator of degraded user experience (real impact, not a proxy).
2. It's actionable -- there's a systematic way to debug and respond.

If an alert fails either test, delete it. (Aligns with Google SRE: urgent, actionable, novel, requires investigation.) Don't buy "AIOps" to suppress alert noise instead of questioning the primitives.
