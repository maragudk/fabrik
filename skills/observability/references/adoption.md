# Debugging, boundaries, and adoption

The practice around the code: how to debug with observability data, where monitoring still belongs, build-vs-buy, and rolling observability out across a team.

## Contents

- [The core analysis loop](#the-core-analysis-loop)
- [Monitoring vs observability: system vs software](#monitoring-vs-observability-system-vs-software)
- [Observability-driven development](#observability-driven-development)
- [Build vs buy](#build-vs-buy)
- [Rolling it out across a team](#rolling-it-out-across-a-team)

## The core analysis loop

When debugging, don't pattern-match against past incidents (intuition doesn't transfer between systems and locks debugging to the longest-tenured person). Debug **from first principles**: assume nothing, form a hypothesis, validate it against the data. This works even when you don't know the architecture or the cause is multi-causal.

The loop:

1. **Start with the prompt.** What did the alert or customer complaint actually tell you?
2. **Verify it's real.** Is there a notable change somewhere? A visualization exposes it as a change in a curve.
3. **Find the dimensions driving the change:**
   - Look at sample rows in the affected area -- any outlier columns?
   - Slice across dimensions looking for patterns; try a `group by` on commonly useful fields like `status_code`, `endpoint`, `hostname`.
   - Filter to specific values to expose outliers.
4. **Know enough?** If yes, done. If not, filter to isolate the affected area as your new starting point and **return to step 3.**

This is a methodical, brute-force sweep that needs no prior system knowledge -- so the best debugger becomes the most curious engineer, not the most experienced.

**Automate the brute-force part.** Rather than sweep dimensions by hand, let the machine diff the anomalous region against the baseline across *all* dimensions and rank by the difference -- "`endpoint=batch` is in 100% of slow requests but 20% of baseline." This requires wide structured events; metrics lack the context and logs need heavy reconstruction first.

**On AIOps:** the realistic role is human + machine. Machines surface *potentially* interesting patterns across billions of rows; humans supply the value judgment (was that spike good or bad, intended or not?). In a fast-changing system where every deploy is technically an "anomaly," automated anomaly detection alone draws its baseline box too small (noisy) or too large (misses real issues). Direct the automation; don't outsource judgment to it.

## Monitoring vs observability: system vs software

They're complementary, not rivals. The dividing line:

- **Monitoring** is for **systems** -- the infrastructure beneath your code (databases, compute, queues). It's reactive, detects known-unknowns, and aggregated metrics are fine here. Established practices: capacity planning, autoscaling.
- **Observability** is for **software** -- the code you actively ship, which changes daily and is judged from the customer's perspective. It's proactive and detects unknown-unknowns via the core analysis loop, which needs high-cardinality fields to isolate one customer's experience.

Rule of thumb for "is it my infrastructure?": if you buy a component as a managed service, it's *not* yours to monitor deeply. If your team installs, configures, upgrades, and troubleshoots it, it is. The deciding factor is **operational responsibility**, not on-prem vs cloud.

**The one exception:** higher-order infra metrics that directly bound software performance -- CPU, memory, disk activity. Engineers *should* watch these as early-warning signals (a deploy that triples resident memory). Capture them *inside* your observability data so system and application signals share context and you can correlate -- ignore the deep noise (`/proc` graphs, kernel-driver metrics) that says nothing about software impact.

## Observability-driven development

Observability belongs early in the lifecycle, not just in production. It complements test-driven development: TDD verifies code against an isolated, deterministic spec; ODD verifies it works in the messy reality of production (fluctuating load, weird user behavior, infra quirks).

- Treat instrumentation as part of writing the feature. The guiding question on every PR: **"How will I know if this change is working as intended?"** Don't merge without an answer.
- **Observability tells you *where*, a debugger tells you *what*.** Use observability to narrow down which component, hop, or subset of users is affected -- then hand off to a debugger or profiler for the code-level cause. Don't emit line-level detail to a telemetry backend; the volume would swamp it.
- **Put engineers on call for their own code**, at least briefly after a merge. Feeling the consequences builds the instinct to instrument well. This is ownership, not punishment.
- **Test against real production traffic** safely with feature flags and progressive delivery. The metric that matters most: time from code written to code in production -- track it and shrink it.
- Ship **one coherent change per merge**. Batching is a top cause of tangled, slow-to-debug breakages. Speed and quality reinforce each other: faster delivery means smaller, more recoverable failures.

The mindset shift: without observability, teams treat production as a glass castle and roll back at the first hint of trouble. With it, production becomes a place you can safely tweak, degrade gracefully, and progressively deliver.

## Build vs buy

At scale teams ask whether to build their own observability stack or buy one. The decision is **not binary -- the usual right answer is buy *and* build.**

You can't compare ROI until you know each path's true total cost of ownership:

- **Building:** the visible cost is engineering *time*; the hidden costs are opportunity cost and "free" software that's free as in puppies, not beer (hardware, salaries, recruiting, training, and forever-maintenance). Whatever you estimate for maintenance, you've underestimated it.
- **Buying:** the visible cost is the *bill*; the hidden costs are future usage growth and **vendor lock-in**. Watch for pricing that penalizes adoption and curiosity (per-seat, per-query) -- successful observability means query volume grows as more teams use the data. Demand pricing transparency.

The recommended shape for most teams: **buy the platform, build the thin integration layer** -- libraries, naming conventions, and abstractions that adapt the vendor tool to your workflows. The key enabler is choosing a vendor with a strong API. And mitigate lock-in by **instrumenting with native OpenTelemetry by default** (use vendor distros only for config), so migrating means swapping exporters, not re-instrumenting -- which is the most labor-intensive part.

## Rolling it out across a team

Observability is a sociotechnical practice, not a checkbox. A few patterns that work:

- **Start with the biggest pain, not a low-stakes pilot.** The common mistake is starting small to de-risk -- but that incurs all the setup cost and demonstrates none of the value. Instead instrument the flaky service that wakes people up, find the answer, and socialize the win.
- **Flesh out instrumentation iteratively.** You don't need complete coverage to get value. Start with auto-instrumentation, then make every new debugging situation an instrumentation opportunity -- when paged, instrument the problem area first.
- **Lower the barrier by leveraging existing work.** Tee an existing log stream to the new backend, add trace IDs to current structured logs, run new instrumentation alongside existing APM for comparison. Familiar names invite interaction and counter the sunk-cost feeling.
- **Plan for the hard last push.** Iterative rollout typically gets you halfway to two-thirds; rarely-touched parts lag once the original pain eases. Set a milestone (make the observability tool the go-to debugging option) and consider a focused push to finish.
- **You have "enough" when** instrumentation rides along with every change and is checked in code review like tests, engineers expect to watch their code through each deploy, and the response to a new unanswerable question is to *add telemetry* rather than guess. Don't over-index on vanity metrics like raw incident count -- finding more incidents can be healthy.

Beyond engineering, the same wide-event data answers questions for support (debug a specific customer's experience), product and customer success (how features are actually used), and executives (connect goals to real user experience). Democratizing it turns those teams into allies.
