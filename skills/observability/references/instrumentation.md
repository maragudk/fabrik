# Instrumentation

How to instrument code so it produces wide, queryable telemetry: structured events, OpenTelemetry, distributed tracing, and sampling. Code examples are in Go (the same concepts apply in any OTel-supported language).

## Contents

- [Structured events](#structured-events)
- [OpenTelemetry concepts](#opentelemetry-concepts)
- [Auto-instrumentation](#auto-instrumentation)
- [Custom instrumentation](#custom-instrumentation)
- [Distributed tracing mechanics](#distributed-tracing-mechanics)
- [Sending data to a backend](#sending-data-to-a-backend)
- [Sampling](#sampling)

## Structured events

An event is a record of everything that happened while one request interacted with your service. Scope one event to one **unit of work** -- for a service, that's usually accepting a request and doing everything needed to return a response.

The construction pattern:

1. On entry, initialize an empty map (a "blob").
2. Throughout the request, append any interesting detail as key-value pairs.
3. On exit or error, emit the entire map as one wide event.

What to attach (aim for breadth -- 300+ fields is normal for mature instrumentation):

- **Request-specific fields:** `user_id`, `session_id`, `shopping_cart_id`, request parameters, every header, the path/endpoint.
- **Runtime fields:** `hostname`, `build_id`/version, container and instance type, region/AZ, runtime stats.
- **Computed during execution:** which downstream services were called and how long each took, intermediate results, variable values you'd want in a debugger.
- **On exit:** total `duration_ms`, `status_code`, error messages.

Events must be **arbitrarily wide** (no fixed schema capping fields), **high cardinality** (accept fields with millions of unique values), and **high dimensionality** (many fields combinable in one query). Avoid backends that require predefined schemas or reject high-cardinality fields -- they force you to predict your questions in advance, which is the opposite of observability.

In modern instrumentation you usually don't build this map by hand -- you attach fields as attributes on the active span (below), and the tracing layer emits the wide event for you.

## OpenTelemetry concepts

OpenTelemetry (OTel) is the CNCF-standard, vendor-neutral instrumentation layer. Instrument once, send anywhere. Key pieces:

- **API** -- vendor-neutral interface for adding instrumentation without binding to an implementation.
- **SDK** -- the concrete implementation; tracks state and batches data for transmission.
- **Tracer** -- starts spans and tracks the currently active one.
- **Meter** -- records metrics (counters, measures). Reach for this only when you need exact, unsampled, process-wide values.
- **Context propagation** -- deserializes inbound trace context from headers (W3C TraceContext or B3), tracks it in-process, serializes it to downstream calls.
- **Exporter** -- translates in-memory OTel objects into a destination format. Defaults to the **OTLP** wire protocol.
- **Collector** -- a standalone proxy/sidecar that receives OTLP, processes it, and fans out to one or more backends.

## Auto-instrumentation

Start here for fast time-to-value. Auto-instrumentation generates spans for incoming/outgoing HTTP, gRPC, and database/cache calls, revealing the service call graph and obvious issues (uncached hot DB calls, slow downstream endpoints).

- **Java/.NET:** attach the OpenTelemetry runtime agent; it auto-detects frameworks.
- **Go:** wiring is explicit. Wrap handlers and clients, e.g.:
  ```go
  // HTTP server
  handler = otelhttp.NewHandler(handler, "operation-name")

  // gRPC server
  s := grpc.NewServer(grpc.UnaryInterceptor(otelgrpc.UnaryServerInterceptor()))
  ```

Auto-instrumentation is the skeleton. It is necessary but never sufficient -- the business-logic context that makes incidents debuggable comes from custom instrumentation.

## Custom instrumentation

Three practices, in rough priority order:

### 1. Add wide fields to the active span

This is the highest-value habit. Batch all per-request metadata onto the span as attributes:

```go
sp := trace.SpanFromContext(ctx)
sp.SetAttributes(
    attribute.String("app.user_id", userID),
    attribute.String("app.shard_id", shardID),
    attribute.Int("http.status_code", code),
    attribute.Bool("app.cache_hit", hit),
)
```

Namespace your custom attributes (e.g. `app.*`) so they're easy to distinguish from auto-generated ones. Record errors too. The richer the dimensions, the more ways you can slice later.

### 2. Start and end spans for expensive internal steps

Wrap costly work (a hot computation, a batch of I/O) in its own span so it shows up as a distinct bar in the waterfall:

```go
var tr = otel.Tracer("module_name") // one tracer per module

func doWork(ctx context.Context) {
    ctx, sp := tr.Start(ctx, "do_work")
    defer sp.End()
    // ...
}
```

`Start` creates a child of whatever span is already in `ctx`, so always thread `ctx` through and pass the returned `ctx` downward.

### 3. Process-wide metrics (only when truly needed)

Prefer recording values as span attributes. Use a meter only for non-request-specific values you need exact and unsampled (e.g. goroutine count, queue depth), scraped periodically.

## Distributed tracing mechanics

A trace is an interrelated series of spans tracking one request across boundaries. It renders as a waterfall. Each span is either the **root** (top-level, no parent) or nested in a parent-child relationship.

### The five required fields per span

Every span needs exactly these to reconstruct the trace:

| Field | Meaning |
|-------|---------|
| **Trace ID** | Unique ID for the whole request. Created by the root span, propagated to every subsequent span unchanged. Use a UUID. |
| **Span ID** | Unique ID for this individual span. |
| **Parent ID** | The span ID of the parent. Defines nesting. **Absent on the root span** -- that absence is how you identify the root. |
| **Timestamp** | When this span's work began. |
| **Duration** | How long the work took (`duration_ms` = end - start). |

Recommended descriptive fields: `service_name` (which service) and a span name (what kind of work). Everything else is tags/attributes.

### Context propagation

Each span emits its own data independently; the backend stitches spans together by ID. To link them across services, trace context travels in **HTTP headers on outbound requests**. Use a standard so both ends agree on header names -- **W3C TraceContext** (default) or **B3**. With B3:

- `X-B3-TraceId` carries the trace ID (unchanged across all spans).
- `X-B3-ParentSpanId` is set to the *current* span's ID; the receiving service reads it and uses it as the parent ID of the span it generates.

So the caller sets the headers from its own trace ID and span ID; the child inherits the trace ID, sets its parent ID from the header, generates a fresh span ID, and emits its own span. That's what builds the tree. With OTel, the propagator handles this for you as long as you thread `context.Context` through every call.

### Beyond service-to-service

The same concepts apply to any correlated work: wrap CPU-hot blocks in spans for finer waterfalls, instrument a monolith, or emit a span per item in a batch job (each S3 upload, each pipeline phase).

## Sending data to a backend

Instantiate exporters once at startup (in `main`). The sensible default is the OTLP gRPC exporter pointed at your vendor or a Collector, wired into a `TracerProvider`:

```go
exp, _ := otlptracegrpc.New(ctx) // OTLP gRPC exporter
tp := trace.NewTracerProvider(trace.WithBatcher(exp))
otel.SetTracerProvider(tp) // now every otel.Tracer() uses it
defer tp.Shutdown(ctx)
```

You can register **multiple** exporters at once -- useful for dual-shipping while evaluating a new tool. Two topologies: export directly from the process, or proxy through a Collector (better for central config, redaction, and routing -- see `adoption.md`).

## Sampling

At scale, retain a representative sample rather than every event. Sampling preserves full cardinality on what you keep (unlike aggregation), so you keep granular drill-down while cutting cost.

### Strategies

- **Constant-probability:** keep a fixed fraction. `if rand.Float64() < 1.0/sampleRate { record }`. Simple, but treats rare errors and common successes the same.
- **Target-rate (dynamic):** adjust the rate to traffic to bound backend cost: `sampleRate = requestsInPastMinute / (60 * targetEventsPerSec)`, recomputed each interval. Good when traffic swings.
- **Per-key:** assign different rates by field value -- e.g. errors 1:1, slow queries 1:5, normal 1:1000; or key on `[customer_id, error_code]`. Best when the key space is small and rates are stable. Validate those assumptions and plan for reversals (an error spike).
- **Per-key + historical:** set each key's rate from its recent volume, so common combinations are sampled harder than rare ones (e.g. Go's `dynsampler-go`).

### Two things that bite people

**Record the sample rate in every event.** With variable rates you cannot reconstruct totals by multiplying by a constant. Pass the current `sampleRate` into the event at record time; then on read:
- counts: sum the represented counts (`Σ sampleRate`)
- sums (e.g. total latency): weight each value by its `sampleRate`
- percentiles: conceptually expand each event into `sampleRate` copies before computing

(Example: values/rates `[{1,5},{3,2},{7,9}]` -- the naive median is 3, but the correctly reweighted median is 7.)

**Make the trace decision consistently.** A trace spans many services with their own rates; independent decisions would shatter traces. Propagate one **sampling ID / trace ID** downstream and derive each keep decision from it (consistent sampling), so whole traces are kept or dropped together and a child sampled at a higher rate never survives while its parent is dropped.

- **Head-based:** decide at trace start from static fields (endpoint, customer); force all children to follow. Needed to guarantee complete traces.
- **Tail-based:** decide at the end from fields like status/latency; keeps interesting outliers but can lose surrounding context unless buffered collector-side.

Prefer OTel/library implementations over hand-rolling, but understand the mechanics so you pick the right method.
