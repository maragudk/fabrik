# Sampling, pipelines, and storage deep dive

Companion to the "Cost, sampling, pipelines, and storage" section of SKILL.md. Covers sampling strategies and code patterns, telemetry pipeline architecture, and the transferable lessons from building observability storage (Retriever and ClickHouse).

## Contents
- Sampling strategies and when to use each
- Head vs tail, and consistent sampling
- Telemetry pipelines
- Storage design principles
- ClickHouse specifics

## Sampling

At scale, storing 100% of events costs more than it's worth -- most events are near-identical successes, and debugging is about patterns and outliers. Keep representative events plus enough metadata to reconstruct the original traffic shape. **Every sampled event carries the sample rate in effect** so the backend can weight it back up (one kept event = N originals).

Strategies and when to use each:
- **Fixed-rate (constant-probability):** keep 1-in-N at random. Simple. Works only when volume is high enough that important errors recur -- probability head sampling at 1% will miss a 0.1% error. Reconstruct counts/sums by multiplying by the rate; percentiles need no adjustment.
- **Recent-traffic-volume (target-rate):** auto-adjust the rate from the request count in the last interval so you sample roughly X events/sec. Predictable cost, no manual tuning during traffic swings.
- **Per-key (content-based):** pick fields (status, endpoint, customer tier) and assign different rates per key combination -- keep all errors, sample successes heavily. Best when the key space is small and relative frequencies are stable.
- **Per-key + dynamic rate:** combine keys with recent per-key volume -- frequently-seen combos sampled aggressively, rare combos kept. Use when traffic content is unpredictable. In Go, `dynsampler-go` (and the OTel samplers) implement this.
- **Multiple static rates:** separate a baseline rate from an outlier rate (errors/slow requests) so the long tail isn't lost to a high overall rate. Add per-key rate-limiting so an error spike doesn't flood the backend.

## Head vs tail, and consistent sampling

- **Head-based:** decide at trace start using static fields (endpoint, customer ID). Propagate the decision downstream via a header bit so the whole trace is kept together. Cheap, in-process.
- **Tail-based:** decide after completion using dynamic fields (status, latency). Requires buffering all spans, usually in an external Collector -- expensive, not feasible purely in-app.
- **Consistent sampling:** derive the keep decision from a propagated trace/sampling ID rather than rolling dice per service. Guarantees whole traces survive together and avoids broken traces (a kept child whose parent was dropped), even when children sample at higher rates than parents.
- **Advanced:** collector-side buffered sampling can upgrade head rates based on a tail heuristic (e.g. a downstream error), combining both worlds.

Pitfalls: reporting raw sampled counts ("100 events" when each represents ~1,000); hardcoding the rate at the receiver instead of passing it in the event; tail-deciding dynamic fields without head propagation (you keep the interesting downstream span but lose its upstream context). Match strategy to traffic shape, validate your frequency assumptions, and have a plan for when they reverse (errors suddenly dominant). Prefer existing libraries over rolling your own, but understand the mechanics to pick the right method.

## Telemetry pipelines

A telemetry pipeline treats data flow as a first-class concern instead of each app hardcoding where its signals go. Like a power grid, it decouples producers from consumers, collapses the many-to-many mesh into a managed stream, and turns telemetry into a reusable asset shared across observability, security, compliance, and BI. It matters now because ingest-priced vendor economics make "send everything everywhere" unsustainable, and OTel (Collector + OTLP) makes pipelines portable.

Stages: **collect -> normalize/secure -> enrich -> reduce -> route**, underpinned by resilience and control/observability.
- **Collect** via OTel Collector receivers; stop tying collection to a single destination.
- **Normalize & secure:** parse unstructured logs into structured events, fix timestamps, convert to a common model (OTLP). Redact PII and apply retention/residency *early*, so all downstream data is clean and compliant.
- **Enrich:** attach infra context (k8s pod/node/region), business context (customer ID, tier), external lookups (IP -> geo). Early enrichment shortens time to detection.
- **Reduce:** filter low-value signals, dedupe, aggregate, and sample *before* data hits expensive backends. This is the biggest cost lever.
- **Route:** fan out the clean stream (logs -> SIEM, metrics -> APM, full-fidelity copies -> cheap archive). Adding/swapping a tool becomes a config change, not reinstrumentation.

Architecture: lightweight **agents** near the source (just reliable forwarding), clustered **gateways** doing the heavy reduction/compliance/routing, and a **control plane** for config/versioned rollouts/fleet management (OpAMP). Start at **agent + gateway** (the standard production pattern) and add a control plane; move to multi-tier regional only when scale/DR/cost demands. Avoid agent-only beyond small setups. Adopt phased, never big-bang: prove on a greenfield app, redirect legacy agents into gateways for central compliance/reduction, then replace legacy agents. Run old and new side by side for a rollback path. Expect roughly 50% ingest savings, reinvest ~10% in pipeline infra, net ~40% plus vendor neutrality.

## Storage design principles

Observability data is **wide structured events** (key-value bags, often ad hoc schema). The defining requirement: any field must be queryable, fast, without pre-aggregation or indexes -- because during an incident you don't know in advance which dimension matters. Optimize for fast-enough results within seconds over arbitrary cardinality, not for exhaustive completeness. The only privileged dimensions are **time** and **partition-by-tenant/service**.

Why traditional stores fail:
- **TSDBs:** every unique tag-combo creates a new series; high-cardinality fields (user/trace IDs) cause cardinality explosion.
- **NoSQL / general DBs:** fast only on pre-indexed fields; indexing every column produces indexes larger than the data.
- **In-RAM:** fast but ~100x SSD cost limits the queryable window to minutes.
- **Row stores:** great for single-row fetch, but mutable overlays need expensive compaction.

Key principles (from Honeycomb's Retriever):
- **Hybrid columnar + time partitioning.** Append-only **segments** by arrival time; one file per field per segment; track each segment's min/max timestamp so queries scan only overlapping segments.
- **Append-only, finalize on thresholds** (e.g. 1 hour / 250k rows / 1 GB). Correct out-of-order arrival at read time, not by inserting into sealed bytes.
- **Compute everything at read time** -- enables ad hoc virtual columns (COALESCE for field migrations, regex extraction) with no on-disk duplication.
- **Compress per-column** with type-aware encodings (dictionary, run-length, delta for timestamps/IDs), prioritizing decompression speed over ratio.
- **Parallelize MapReduce-style** -- each segment processed independently; serverless workers over object storage can beat a single SSD node. Once ~90% of subqueries return, re-request the slowest 10% in parallel and race them.
- **Tier by age:** hot recent data on SSD, offload older segments to object storage.
- **Durability via a streaming log** (Kafka): stateless receivers produce; deterministic indexers consume in order; restart from a checkpointed offset.

Anti-patterns: single-use columns (`timestamp_2025...`) instead of a stable column name + value as data; special-casing `trace_id` as a lookup index (blocks cross-trace analysis); grouping by raw high-cardinality fields (OOMs reducers, produces useless 100k-line graphs). Don't over-engineer for small volumes -- a single-binary store beats a multi-service architecture until scale demands otherwise, but keep a path to scale. "If your problems are too hard to solve, you have the wrong data abstraction."

## ClickHouse specifics

ClickHouse is a columnar, SQL-native analytics DB well-suited to write-once, append-heavy telemetry. Treat observability as "just another data problem": store wide high-cardinality events and compute aggregates/relationships at query time.

- **MergeTree:** a table is many immutable **parts** (one per insert), each sorted by the ordering key; background merges consolidate them. Rows group into **granules** (~8,192 rows); a sparse primary index records the first key per granule. Query path is layered pruning: partition -> part (min/max) -> granule (binary search) -> columnar scan -> lazy materialization of heavy columns.
- **Primary key = your dominant filter order** (`(ServiceName, Timestamp)` vs `(Timestamp, ServiceName)`); it's immutable and dictates pruning efficiency.
- **Hybrid schema:** a few hot typed columns plus a `Map(String,String)` for evolving attributes; materialize map keys into real columns once they become hot. (The 2025 `JSON` type automates this.) Typed columns beat `LIKE` on log strings.
- **Skip indexes** (bloom, tokenbf, minmax) only help when positives cluster in few granules. **Projections** give alternate primary keys within one table. **Materialized views** shift work to ingest time. `ASOF JOIN` correlates independent streams at query time.
- **Scale vertically first** -- ClickHouse exploits big hardware and avoids the network (one 32-core/128GB node ~ 20B events/day; ~10-20x compression). Shard for capacity, replicate for HA (different concerns). Tiered TTL: hot on SSD, age out to object storage, then delete (`ttl_only_drop_parts=1`, partition coarsely).
- Pitfalls: maps read all keys per access and can't be in the primary key; fine-grained partitions break optimization; updates/deletes are slow (keep off the hot path); batch inserts or use `async_insert=1` (idempotent, so retries are safe). Profile with system tables; optimize from measurement.
