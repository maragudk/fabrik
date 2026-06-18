# Strategy, decisions, and organizational change

Companion to the "Strategy, decisions, and organizational change" section of SKILL.md. For when you're advising on observability strategy, not just writing instrumentation. Covers build-vs-buy, vendor partnerships, observability-team practices, the business case, the systems-thinking lens, and the organizational shift.

## Contents
- Build vs buy vs open source
- Vendor partnerships and procurement
- Instrumentation for observability teams
- The business case and diagnosing the investment
- Systems thinking for software delivery
- The organizational shift and learning speed

## Build vs buy vs open source

Build-vs-buy is not binary or technical -- it's an economic bet on where you spend your scarcest resource: engineering cycles. AI makes writing code cheap, but maintenance cost is unchanged (often higher for AI-generated code).

Use a 2x2 of **business value** (none -> differentiator) against **ubiquity** (commodity -> bespoke):
- **Buy** (commodity + low value): most infra -- logging, identity, observability platforms. If it doesn't differentiate you, buy it.
- **Build** (bespoke + high value): your actual core competency. Justifies custom code.
- **Should not exist** (bespoke + low value): unique-but-useless tech debt; obliterate and replace.
- **Decide** (commodity + high value): the only quadrant worth real debate.

Key distinction: business value = revenue/market-share impact, NOT importance. Your secrets vault is critical but adds zero market share. Channel build cycles only at problems unique to your business model.

Rules of thumb:
- Closer to bits-on-disk -> buy battle-tested code. Closer to UX -> custom is fine. (New database = need a great reason; thin OTel wrapper for frontend = normal.)
- Pattern: **infra/storage = buy; UX/workflow = build small; intelligence or >3-month builds = build only with strong product-management commitment.**
- Observability is special: it watches the watchers. Decouple it from your prod stack/region/cloud, or it goes dark exactly when you need it -- part of what you pay a vendor for is that independence and HA.
- OSS is "free as in puppies, not beer" -- costs shift to engineer time, infra, maintenance, and hiring for niche expertise. An in-house "free" ELK stack can cost more than a vendor quote.
- The winning default: **buy the platform, build the integration layer** -- an observability team writing wrappers, naming standards, and abstractions on a vendor's API. Default to OTel + exporters so instrumentation survives a migration; the vendor's proprietary agent is lock-in.

Anti-patterns: treating internal builds as "free" because salaries are sunk (ignoring opportunity cost); engineer NIH bias and sunk-cost fallacy; promoting engineers for lines of code / big builds instead of business outcomes; vendor pricing that penalizes adoption (per-seat/host/query metering) -- demand transparent 1-2 year cost forecasts. Building is right only for truly unique needs, hyperscale economics, observability as your core product, or regulatory bars on external vendors.

## Vendor partnerships and procurement

Buying observability tooling is engineering, not paperwork -- the vendor affects every engineer's productivity for years. "Vendor engineering" means wielding influence without authority across company lines. The transformations that succeed pair a top-down mandate with a bottom-up groundswell.

Concrete practices:
- **Map stakeholders by their wins, not their function** (engineering, management, finance, IT/security, procurement). Translate your case into their currency -- business outcomes for finance/execs, daily pain relief for engineers.
- **Build credibility and trust separately.** Credibility = you assert something true and it proves true (be conservative). Trust = you prove you have their interests at heart (extend yourself first).
- **Run a meaningful POC:** a load test of your *hardest* problems and representative use cases in production. Define specific, measurable success criteria before you start, and get someone close to the budget to agree they're the right ones.
- **Adopt OpenTelemetry before evaluating**, so reinstrumentation happens once and you can dual-write to old and new tools during migration.
- **Migrate in three steps:** de-risk with a manageable example -> bulk move (accept messiness) -> iterate service-by-service to clean up. Plug milestones into OKRs or the work gets bumped. Build new config from scratch, not an export of old cruft. You only reap cost benefits once the old tool is decommissioned.
- **Use SLAs as levers** -- they encode the relationship and drive vendor behavior after everyone involved has moved on.

Rules of thumb: internal stakeholders -- you're the supplicant (same team, you ask); vendors -- assume opposite goals, verify everything. Aim for reciprocity (both sides want to high-five after signing). The website price is meaningless -- find a similar customer who'll share real numbers. Polish anything that might get escalated (execs trust polished artifacts). Plan the next transition now; requalifying alternatives on a cadence often wins discounts. Pitfalls: going dark in the review pipeline; surprising the C-level with bad news late; letting the vendor write your requirements; accepting a proxy "no" (find out who "they" are -- usually security, and most compliance is flexible with evidence).

## Instrumentation for observability teams

An observability team's real job is **defining and governing the shared language** of telemetry, not handing out dashboards. Instrumentation is a constructed language that must be gardened; adoption spreads like human language (education, dictionaries, repetition).

- **Semantic conventions** are the most valuable part of OTel: a shared vocabulary (`http.request.method`, `db.system`) plus grammar (dot-namespaces, families, stability levels). Two heuristics carry most of the weight: namespace by specificity left-to-right, and define actors as client/server or producer/consumer. Use OTel's domains and Weaver to define your own; don't reinvent.
- **Treat telemetry schemas like a versioned API contract** living near the code: enables discovery, linting, codegen, compile/runtime verification, and safe in-flight evolution (pipeline processors normalize before alerting). Start from "why" (the questions users actually ask); namespace shared business attributes at the right level (`acme.transaction.id` org-wide vs `acme.serviceName.transaction.id` service-scoped); DRY across signals; keep high-cardinality IDs off metrics and layer a low-cardinality companion (`customer.region`/`tier`) to navigate between signals.
- **Paved paths:** the right way and the fastest way must be the same way. Embed OTel + a basic schema into the RPC/service framework so context propagation is automatic and adoption is a library bump. Meet engineers where they already are (one link from the alert graph they already check can triple usage). Make adoption safe: dual-send to cheap blob storage during migrations to prove nothing's dropped; centralize pipeline config so dropped data is explainable.
- **Secure/regulated environments:** the core tension is security = isolation, compliance = evidence, observability = correlation -- and correlation can silently de-anonymize "locally safe" data. Use one-way org-consistent hashes/tokenization to keep correlation power without exposing IDs; expect mTLS, encryption at rest, control-plane proxies. Design incentives so partners look good helping you; shift the *value* left, not just the burden.
- Anti-patterns: wrapping the OTel API (renaming calls); rolling out agents + prebuilt dashboards as a fait accompli; chargeback as a stick (breeds resentment); exposing the full verbose SDK instead of a one-liner; high-cardinality fields on time-series metrics. Measure success by subtler wins (week-long incidents shrink to days; SLOs spoken at exec level), not data volume or dashboard count.

## The business case and diagnosing the investment

Observability is two feedback loops, and the business case differs for each:
- **Operational loop** -- downstream, delayed, threshold-based; fires after users are hurt. The safety net. Govern as a **cost center**: optimize for reduced spend, predictable overhead, coverage. ROI is concrete (uptime, MTTD/MTTR, prevented outages, reduced burnout).
- **Developer learning loop** -- upstream, compounding; validates intent against production before anything breaks. Govern as **strategic investment**: optimize for learning speed and competitive advantage. Answers "am I building the right thing? how are users using it? what happened when I shipped X?"

You cannot get learning-speed outcomes under cost-center governance. The recurring failure is a **posture mismatch**: paying for observability as a capability, operating it like a cost center, using it like monitoring. Decide which loop is your real bottleneck before spending or cutting.

- **Close the loop.** Activity without learning is waste: chaos engineering without attribution is just chaos; feature flags without validation are a trust-fall; progressive delivery without per-cohort regression detection is just a slower pipeline. The pattern that works is change -> observe -> act.
- Quantify value on two axes: external (customer outcomes -- anchor on differentiators and SLO'd revenue paths; UX latency moves money) and internal (engineer velocity -- lean on DORA/SPACE/DX; salaries are the largest cost, so tooling is a force multiplier).
- Diagnostic signals it's working: time-to-identify-known-causes dropping; deploy frequency up while batch size down; more people debug independently; hypothesis-to-validation time shrinking; more issues caught internally before customers. If spend rose but none of your target indicators moved, change tooling/instrumentation/approach -- not the messaging.
- Practical moves: cap each investment at its point of diminishing returns; tiered telemetry pipelines (rich traces for critical-path/under-development, health checks for stable/internal); invest in attribution ("observability for your observability" -- tag each request with its run cost and originating code) and give teams budgets.
- Avoid the firefighting trap (prizing incident response while never explaining why fires start -- the goalie making 50 saves means the defense is broken) and blind cost-cutting (ingesting less data creates blind spots and higher long-term cost). Don't starve high-cardinality data to save cost -- you lose the specificity that finds outliers. The worst outcome isn't the wrong tool (recoverable); it's spending before aligning on what you're solving and which loop you're improving.

## Systems thinking for software delivery

Software delivery is a **sociotechnical system** -- tech and human behavior co-produce outcomes; jointly optimize both. Observability is an information flow that closes feedback loops; without it you have causes and effects with no logical link. The leverage isn't more effort (firefighting burns energy without changing the system) -- it's improving the sensing mechanism.

Every core capability is a loop needing sense -> interpret -> respond (deploy, code review, incident, product). Two loop types: **amplifying** (self-reinforcing -- virtuous cycle or death spiral) and **balancing** (stabilizing). The difference between a virtuous cycle and a death spiral is not intent -- it's whether the system can see clearly enough to self-correct.

Practices: instrument the critical path uniformly *before* scaling complexity; build the confidence loop (good signal -> frequent small deploys -> easier debugging -> lower MTTR -> more trust -> more speed); apply observability to your observability (trace volume vs query usage, cardinality explosions, cost-per-value). Anti-patterns: executives picking all tooling without the engineers who live with it; buying your way out of a sociotechnical problem; partial/inconsistent observability (worse than uniformly poor -- false security accumulates); safety theater (change advisory boards, deploy freezes, no-deploy-Fridays, stale runbooks). Target information flows, not surface tweaks (budgets, metrics, and locations get absorbed). You can find the right leverage point and still push it the wrong way (deploys: right lever, wrong direction -> release trains). Degraded feedback doesn't just slow you -- you learn the wrong lessons and ossify.

## The organizational shift and learning speed

In the AI era the bottleneck is no longer how fast you write code but how fast you can validate, understand, and learn from it in production. AI amplifies whatever practices you already have. When agents ship faster than humans can review, observability is the last surviving quality gate. **Sociotechnical debt** -- misalignment between social structures and technical systems -- is the real blocker, and AI speed turns it from tolerable to existential.

Three debts to fix: developers living in tests not production (wire production signals into daily dev); telemetry treated as infrastructure not product (go deep, not broad); dev tooling never designed as a product (platform engineering that treats developers as customers and encodes wisdom into defaults and paved paths).

Buying tools and renaming the monitoring team changes the label, not the capability. Real observability is an organizational change in who owns production and what "good" means. Diagnose with evidence-based tests:
- **Ownership test:** after merging, how does an engineer know their code works? (Real: notification + link, canary, live metrics within minutes.)
- **Two-or-three-people test:** can engineers investigate production themselves, or escalate to the same few seniors? Aim for 60-80% independent.
- **Mystery test:** "what's weird about prod that we just accept?" Persistent folklore = accumulated blindness.
- **Arbitrary-question test:** pose a novel query sliced by un-preconfigured dimensions. Real: answered in under 60s. Legacy: "we don't track that combination." This is the monitoring-vs-observability line.
- **Deployment-confidence test:** how much fear surrounds deploys? Read-only Fridays and CABs = fear of not knowing.

Drive change: build a coalition of people whose pain is immediate; honor the heroes holding prod together (excluded, they stall you silently); secure a mandate (makes the new way required for new work), not just sponsorship (theater); pitch capability and risk/burden reduction, not consolidation or cost. Roadmap: depth over breadth (instrument one mid-importance domain completely as undeniable proof); pave the path; run as a platform/product team; buy commodity, adopt open standards, build only what's unique; match people to phases (pioneers build, settlers harden, town planners optimize); treat it as a multiyear capability and re-run the tests at 6 months to prove wins. The AI forcing function: orgs without real observability will "ship faster and understand less" -- build genuine observability before the volume hits.

Litmus questions to carry: Can every developer pinpoint the effects of their last diff? Does incident resolution depend on a specific rockstar? Could a six-month hire instrument a new service correctly without pinging three people? Success metrics: shrinking time from deploy to validated understanding of customer impact; rising share of incidents caught by internal telemetry before customer reports; rising share of deploys with a post-deploy outcome check.
