# Observability for AI: agents and LLM applications

Companion to the "Observability for AI" section of SKILL.md. Covers the agent context layer, AI agents for observability, observability-driven development with AI, LLM application telemetry, and the eval flywheel.

## Contents
- The context problem
- AI agents for observability: use cases
- Observability-driven development with AI
- Observability for LLM applications
- The AI-sandwich architecture

## The context problem

An observability agent is an LLM reasoning engine plus tools (query telemetry, call APIs, run code). The durable principle: **agents are only as good as the context they're given.** A senior engineer carries an implicit mental model built over months -- service topology, naming chaos, system history, what "normal" looks like. An agent querying telemetry cold has none of it. The biggest differentiator in agent effectiveness is not the model but the completeness of the operational context. Worse, coding agents now remove engineers from the details, so the institutional knowledge that fed that mental model erodes. Building a maintained, machine-readable **context layer** is the central, least-solved problem.

Context layers an agent needs:
- **Service topology** -- what calls/depends on what; core vs edge; critical paths.
- **Naming conventions** -- a canonical map of aliases, owners, and what each service actually does (`user-service` vs `users-svc` vs `svc-user`).
- **Deployment context** -- recent changes, where risk is elevated.
- **Known issues** -- degraded dependencies, long-running bugs, broken telemetry you can't take at face value.
- **Recent incidents** -- last 30 days: services, duration, blast radius, confirmed root cause.
- **Business context** -- which endpoints are revenue-critical; what a latency/error change means to the business.

Agents aren't usually hallucinating -- they're optimized for confidence and reason rationally from incomplete context. The dominant failure mode is **inferring meaning incorrectly** (reading a calculated `is_slow` column as a feature flag). Fix it with clear field/tool descriptions, not more prompting. Everything that helps an agent reason also helps a human run the core analysis loop.

## AI agents for observability: use cases

Frame agents by where context lives and by autonomy (error compounds with autonomy):
- **Copilot** -- alongside you (analyzing traces/stack traces); just restart when it loses the plot.
- **Commander** -- you set goals, it executes with tools; weaker transfer of understanding to you.
- **Caretaker** -- autonomous, in the path of alerts/deploys; small interpretation errors can cascade.

Humans own the outcomes regardless of mode. Keep agent scope narrow: the agent does the groundwork, the human makes the judgment call at the boundary.

Proven use cases:
- **Incident response:** automate the mechanical first 15 minutes (pull dashboards, recent deploys, blast radius, parallel queries) into a structured summary. Augment the on-call engineer; don't auto-resolve.
- **Explaining telemetry:** translate stack traces, slow waterfalls, and metric shifts into plain language ("this is an N+1 from an ORM misconfig"). Compresses senior expertise for juniors.
- **Improving instrumentation:** given a function or PR, flag missing or poorly structured spans/attributes and apply team conventions at authorship time.
- **Adjacent wins (run continuously):** audit alert configs against real incident history; propose data-grounded SLOs and flag drift before breach. These remove the activation energy for chronically deprioritized work.

Anti-patterns: querying a cold telemetry store with natural language (the agent doesn't know what it doesn't know); conflating correlation with causation without a topology model; vague prompting ("add observability to this service"); treating context as the agent's problem to figure out on its own. Naive piping-logs-to-LLM works only in small, well-named, well-instrumented systems -- exactly the ones that matter least.

## Observability-driven development with AI

- AI makes instrumenting easy, but **working telemetry is not useful telemetry.** Agents invent attributes, duplicate signals, and create noisy traces.
- Put observability guidance in agent config under one header; be detailed and direct. Map attribute sources explicitly ("each route handler must set `app.customer.id`/`app.customer.plan_type` from request-context `customerId`/`plan`"). Reference standards like OTel.
- AI makes code cheap, so carrying cost rises. Counter it: have AI use **centralized helper libraries of attribute constants** rather than inventing keys, and reuse migration prompts to modernize legacy telemetry.
- Blend testing and ODD: use OTel Weaver schemas as CI static checks, and give agents the schema plus local telemetry validation for tight, self-verifying loops.

## Observability for LLM applications

LLMs are non-deterministic and opaque: the same input may not yield the same output, you can't attach a debugger, and natural-language inputs span an unbounded space. Traditional observability still applies to the deterministic parts; the non-deterministic part needs a **learning flywheel** -- production telemetry feeds evaluations, evals inform prompt/harness improvements, improvements show up again in telemetry. This loop moved a Honeycomb feature from a 25% error rate to under 1%.

Why traditional proxies fail:
- Latency proxies (Apdex, time-to-first-token) mislead -- a fast but wrong answer doesn't satisfy users.
- In agentic flows, a single failed operation isn't the signal; whether the **overall task completed** is what matters.
- Cost (GPU/token spend) is a first-class concern.

Evaluations resemble unit tests but allow three outcomes (pass / fail / maybe):
- **Question evals:** extract known facts from hand-crafted golden data; score with simple string matching.
- **Task evals:** fuzzy, judgement-based workflows; no single right answer -- score the steps taken, token count, and whether specific conclusions appear. Use LLM-as-a-judge for pass/fail, then manually review a sample on a regular cadence.
- Evals only cover the LLM-interaction slice; great evals can still hide a terrible UX. Observability fills the gap.

Telemetry design to apply:
- Lean on OTel **GenAI semantic conventions**; client libs auto-emit token counts, model name, sampling params, system prompts.
- For huge/sensitive inputs and outputs, store a **link to a system of record** rather than inlining the value; respect privacy/regulation (users overshare).
- Make it easy to **promote a production trace into an eval.**
- **Derive cost at query time** from model + token counts rather than baking in a cost attribute -- lets you compare prompt/model versions cheaply.
- Capture **user-feedback signals** (thumbs up/down, retries) as attributes -- a better UX signal than errors/latency.
- Instrument the *connections* between the LLM and the rest of the system (auth, DBs, tools), not just the model call. Track upstream provider behavior: rate limits, retries, latency, cache-hit info.
- Use **SLOs, not threshold alerts**, for intermittent provider timeouts -- threshold alerts here are unactionable noise.
- **A little code beats more prompting** sometimes: programmatically correcting malformed JSON took Honeycomb from 25% to 14% before prompt work took it under 1%.
- **Test in prod** -- you cannot enumerate every NL interaction, and decisions have roughly a 6-month shelf life.

Anti-patterns: treating LLM apps like deterministic software with exhaustive offline tests; threshold alerting on things you can't control; trusting public benchmarks as proof of value; analyzing telemetry on a single axis (errors only).

The eval flywheel loop: (1) pull real production inputs, decide the ideal output for each; (2) add representative cases to the golden dataset and prune unrepresentative ones; (3) rerun evals and compare to historical trends (expect a drop when real usage first lands). Track eval pass rate as an SLI; a drop is a reliability incident.

## The AI-sandwich architecture

Where correctness is definable, sandwich the non-deterministic AI layer between two deterministic layers, separating the system's **physics** (immutable rules) from its **imagination** (the LLM). Never execute an AI proposal directly -- feed it to the rules engine as a hypothesis to test (valid output? constraints held?). The **proposal-rejection rate** becomes your highest-fidelity AI-reliability signal.

Three CI gates: **deterministic** (hash stability, arithmetic, coverage -- binary pass/fail); **simulation** (run the AI's plan through the engine; predicted delta must match within tolerance); **semantic** (golden dialogs plus a confidence floor). Close the loop: when the rule engine rejects a proposal, capture the exact inputs, scrub PII, and promote them to a golden test fixture. See `instrumentation.md` for ontology and invariant design.
