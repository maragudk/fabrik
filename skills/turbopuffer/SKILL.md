---
name: turbopuffer
description: Guide for building search on turbopuffer, the object-storage-native vector and full-text search engine. Use this skill whenever the user is writing or modifying code that talks to turbopuffer -- anything importing `github.com/turbopuffer/turbopuffer-go`, calling `*.turbopuffer.com` endpoints, or mentioning tpuf or turbopuffer namespaces -- and when designing features it could serve, such as semantic/vector search, BM25 full-text search, hybrid search with RRF, or RAG retrieval with filters. Also use it when deciding whether turbopuffer fits a use case, designing namespaces or schemas for it, or debugging its consistency, caching, backpressure, or HTTP 429 behavior.
license: MIT
---

# turbopuffer

## Overview

turbopuffer is a search engine (vector, full-text, hybrid, filters) built natively on object storage. Object storage is the only source of truth; NVMe SSD and memory are caches in front of it. That architecture makes it very cheap at rest, fast when warm (vector p50 ~14ms on 10M docs), and slower when cold (p50 ~500-900ms) or writing (p50 ~165ms for a 512KB batch, since every write is an object-storage PUT).

Reach for it when you have: RAG/semantic search, hybrid search (BM25 + vectors), naturally partitioned data (per-tenant namespaces), or large scale at low cost. It is deliberately *not* a fit for: a free tier (commercial only), heavy first-stage ranking logic (it does first-stage retrieval; rerank in your own code), or built-in embedding as a primary workflow (bring your own vectors; native embedding exists but is in private beta).

There is no local emulator and no open-source version. Tests and development hit the real service (see Testing below).

## Mental model

- A **namespace** is an isolated container of documents with its own indexes — a prefix on object storage. Namespaces are created implicitly on first write, scale to hundreds of millions per org, and are near-free when idle. **Design rule: one namespace per set of documents queried together (e.g. per tenant), not one big namespace with filters.** Smaller namespaces are faster and cheaper.
- A **document** has an `id` (u64, UUID, or string ≤64 bytes), optional vectors, and **attributes**. Attribute types are consistent per namespace and tracked in a per-namespace **schema** (auto-inferred by default; declare explicitly for `uuid`, `datetime`, vectors beyond `vector`, FTS, and to disable indexing).
- **Writes** append to a write-ahead log on object storage: durable when the call returns, immediately visible to strongly consistent queries. Concurrent writes to a namespace group-commit; **each namespace commits at most ~1 WAL entry/second**, so batch instead of looping single writes. Indexing happens asynchronously on separate nodes; unindexed data is searched exhaustively in the meantime.
- **Queries** default to strong consistency, which costs a ~10ms floor (an object-storage metadata check). Eventual consistency skips that and scans at most 128 MiB of unindexed data; it can be stale up to ~1h after very large writes.
- Vector indexing uses **SPFresh** (centroid-based ANN, tuned for 90-100% recall@10, measured continuously on 1% of live traffic). Full-text search is a native BM25 inverted index. Filters use inverted indexes that cooperate with the ANN index, so filtered vector search keeps recall.
- First query to a cold namespace reads object storage directly (3-4 roundtrips); subsequent queries hit NVMe/memory cache on the same node. You can pre-warm (see below).

## Client setup (Go)

```go
// go get github.com/turbopuffer/turbopuffer-go/v2
import (
	"github.com/turbopuffer/turbopuffer-go/v2"
	"github.com/turbopuffer/turbopuffer-go/v2/option"
)

tpuf := turbopuffer.NewClient(
	option.WithAPIKey(os.Getenv("TURBOPUFFER_API_KEY")), // default; can be omitted
	option.WithRegion("gcp-europe-west1"),               // or TURBOPUFFER_REGION env var
)
ns := tpuf.Namespace("my-namespace")
```

Reuse one client for connection pooling. Region is part of the base URL (`https://<region>.turbopuffer.com`); pick the one closest to your backend. Regions span AWS (e.g. `aws-eu-central-1`, `aws-us-east-1`) and GCP (e.g. `gcp-europe-west1`, `gcp-us-central1`); full list at https://turbopuffer.com/docs/regions.

The client retries connection errors, 408, 409, 429, and 5xx with exponential backoff (4 retries by default; tune with `option.WithMaxRetries`). Errors unwrap to `*turbopuffer.Error` via `errors.As`. Optional scalar params use helpers: `turbopuffer.Bool(true)`, `turbopuffer.Int(10)`, `turbopuffer.String("x")` — prefer these over `param.NewOpt`, which needs an extra import the docs snippets forget.

Namespace names must match `[A-Za-z0-9-_.]{1,128}`. Attribute names can't start with `$`.

## Writing documents

One endpoint does everything: upserts, patches, deletes, and namespace copies, atomically per request.

```go
res, err := ns.Write(ctx, turbopuffer.NamespaceWriteParams{
	UpsertRows: []turbopuffer.RowParam{
		{"id": 1, "vector": embedding, "text": "walrus narwhal", "public": true},
		{"id": 2, "vector": embedding2, "text": "pufferfish clownfish", "public": false},
	},
	DistanceMetric: turbopuffer.DistanceMetricCosineDistance,
	Schema: map[string]turbopuffer.AttributeSchemaConfigParam{
		"text": {Type: "string", FullTextSearch: &turbopuffer.FullTextSearchConfigParam{}},
	},
})
// res.RowsAffected, res.RowsUpserted, ...
```

Write params (all optional, combined freely):

- `UpsertRows` / `UpsertColumns` — insert or **fully overwrite** documents (row vs columnar format).
- `PatchRows` / `PatchColumns` — partial update of listed attributes only. Patches to missing IDs are silently ignored. **Vector attributes cannot be patched.**
- `Deletes` — delete by ID (`[]any{1, 3}`).
- `DeleteByFilter` / `PatchByFilter` — filter-driven bulk ops (max 5M / 50k rows per request; `rows_remaining` in the response tells you to reissue). Read Committed semantics.
- `UpsertCondition` / `PatchCondition` / `DeleteCondition` — conditional writes (below).
- `DistanceMetric` — `cosine_distance` or `euclidean_squared`. Required on writes to a namespace with vectors.
- `Schema`, `Sharding`, `Encryption`, `CopyFromNamespace`, `BranchFromNamespace`, `DisableBackpressure`.

Batch aggressively: up to 512 MB per request, batching earns up to a 50% write discount, and per-namespace throughput is ~10k writes/s only when batched. Duplicate IDs in one request are an error (HTTP 400).

### Schema and types

Types: `string`, `int`, `uint`, `float`, `bool`, `uuid`, `datetime` (ISO 8601 strings), array forms (`[]string`, `[]uuid`, ...), vectors `[N]f32` / `[N]f16` / `[N]i8`, multi-vector `[][N]f32` (late interaction), sparse `{}f16`. Only `string`/`int`/`bool` (and arrays of them) are inferred — declare the rest explicitly, or they land as the wrong type permanently. An attribute literally named `vector` is inferred as a vector.

Per-attribute schema options: `Ann` (required `true` for extra vector columns), `Filterable` (default true; **set false on large attributes you never filter — 50% storage discount and faster indexing**), `FullTextSearch` (bool or config object), `Regex`, `Glob`, `Fuzzy` (each enables the matching filter operators; each defaults `filterable` to false when enabled), `SparseKnn`, `Embed`.

Schema changes in place: `filterable`, `full_text_search`, `regex`, `glob`, `fuzzy`, adding/removing `embed` — via a document-free write with only `Schema` set, or `ns.UpdateSchema`. Type changes and attribute deletion require export + re-upsert into a new namespace. A namespace has max 2 vector columns, **fixed at creation**; all documents must include all vector attributes.

### Conditional writes

Conditions are filters evaluated atomically against the current document (Serializable semantics); `NewExprRefNew` references the incoming value. Documents that don't exist are written unconditionally.

```go
res, err := ns.Write(ctx, turbopuffer.NamespaceWriteParams{
	UpsertRows: []turbopuffer.RowParam{{"id": 1, "vector": v, "updated_at": "2026-07-31T12:00:00Z"}},
	UpsertCondition: turbopuffer.NewFilterOr([]turbopuffer.Filter{
		turbopuffer.NewFilterLt("updated_at", turbopuffer.NewExprRefNew("updated_at")),
		turbopuffer.NewFilterEq("updated_at", nil),
	}),
	DistanceMetric: turbopuffer.DistanceMetricCosineDistance,
})
```

Conditional and filter-based writes are billed as a write plus one or two queries.

## Querying

```go
res, err := ns.Query(ctx, turbopuffer.NamespaceQueryParams{
	RankBy:            turbopuffer.NewRankByAnn("vector", queryEmbedding),
	Limit:             turbopuffer.LimitParam{Total: 10},
	Filters:           turbopuffer.NewFilterEq("public", true),
	IncludeAttributes: turbopuffer.IncludeAttributesParam{StringArray: []string{"text"}},
})
for _, row := range res.Rows {
	// Row is a map[string]any: row["id"], row["$dist"] (the rank score),
	// and the requested attributes like row["text"]
}
```

### rank_by variants

- `NewRankByAnn("vector", []float32{...})` — approximate nearest neighbor.
- `NewRankByKnn(...)` — exact search; requires filters, costs 2 concurrency slots.
- `NewRankByTextBM25("text", "query")` — full-text relevance.
- `NewRankByAttribute("created_at", "desc")` — order by attribute (no `$dist`; arrays not orderable).
- `NewRankBySparseKnn("sparse", map[string]float64{...})` — sparse vectors.
- Combine BM25 clauses: `NewRankByTextSum`, `NewRankByTextMax`, `NewRankByTextProduct(2, ...)` for boosting; `NewRankByTextSaturate`/`NewRankByTextDecay`/`NewRankByTextDist` for popularity and recency signals.

Weighted multi-field text search:

```go
RankBy: turbopuffer.NewRankByTextSum([]turbopuffer.RankByText{
	turbopuffer.NewRankByTextProduct(2, turbopuffer.NewRankByTextBM25("title", "quick fox")),
	turbopuffer.NewRankByTextBM25("content", "quick fox"),
}),
```

Documents scoring zero are excluded from results. `Limit.Total` maxes out at 10,000; `Limit.Per` diversifies (max N results per attribute value). `TopK: turbopuffer.Int(10)` is a shorthand for `Limit`.

### Filters

Constructors mirror the wire operators (`turbopuffer.NewFilter*`):

- Comparison: `Eq`, `NotEq`, `In`, `NotIn`, `Lt`, `Lte`, `Gt`, `Gte` (+ `AnyLt` etc. for array elements). `Eq(attr, nil)` matches missing attributes; `Lt`/`Lte` also match null.
- Arrays: `Contains`, `NotContains`, `ContainsAny`, `NotContainsAny`.
- Text/pattern (need the matching schema flag): `Glob`, `IGlob`, `NotGlob`, `NotIGlob`, `Regex` (no lookaround/backreferences), `Fuzzy` (edit-distance options). Anchored patterns (`turbo*`) use the trigram index; unanchored ones degrade toward full scans.
- Tokens (need FTS enabled): `ContainsAllTokens`, `ContainsAnyToken`, `ContainsTokenSequence` (phrase match).
- Logical: `NewFilterAnd([]turbopuffer.Filter{...})`, `NewFilterOr(...)`, `NewFilterNot(...)`. Filters on `id` work fine.

### Aggregations

`AggregateBy` (mutually exclusive with `RankBy`) with `NewAggregateByCount()` / `NewAggregateBySum(attr)`, optionally grouped:

```go
res, err := ns.Query(ctx, turbopuffer.NamespaceQueryParams{
	AggregateBy: map[string]turbopuffer.AggregateBy{"n": turbopuffer.NewAggregateByCount()},
	GroupBy:     []turbopuffer.GroupBy{turbopuffer.NewGroupByAttr("category")},
})
// res.AggregationGroups
```

Aggregate/group-by queries scan the namespace and consume 4 concurrency slots — don't put them on hot paths.

### Pagination and export

There is no export endpoint; paginate the query API by ID:

```go
var lastID any
for {
	params := turbopuffer.NamespaceQueryParams{
		RankBy: turbopuffer.NewRankByAttribute("id", "asc"),
		Limit:  turbopuffer.LimitParam{Total: 10_000},
	}
	if lastID != nil {
		params.Filters = turbopuffer.NewFilterGt("id", lastID)
	}
	res, err := ns.Query(ctx, params)
	if err != nil {
		return err
	}
	// process res.Rows ...
	if len(res.Rows) < 10_000 {
		break
	}
	lastID = res.Rows[len(res.Rows)-1]["id"]
}
```

For plain replication (no transformation), prefer `ns.CopyFrom` — server-side, up to 75% write discount, works across regions, clouds, and orgs.

## Full-text search configuration

Enable per attribute (`string` or `[]string`). The zero-value config gets sensible defaults: `word_v4` tokenizer, English, case-insensitive. Tune via `FullTextSearchConfigParam`: `Language` (18 languages), `Stemming` (default false), `RemoveStopwords`, `CaseSensitive`, `AsciiFolding`, `MaxTokenLength`, tokenizer, and BM25 parameters `K1` (default 1.2, term-frequency saturation), `B` (default 0.75, length normalization), `K3` (default 8.0, query-term saturation). The `pre_tokenized_array` tokenizer takes client-side tokens in a `[]string` attribute — the same tokenizer function must be applied at write and query time.

Search-as-you-type: BM25 and token filters accept a last-token-as-prefix option (`Bm25ClauseParams`/filter `WithParams` variants). Result highlighting is available via `compute_attributes` with `NewExprHighlight` (beta). FTS changes rebuild in the background; queries serve the old config until the new index is ready.

## Hybrid search

Run vector and BM25 in one request with `MultiQuery` (same snapshot, up to 16 subqueries), fused server-side with reciprocal rank fusion:

```go
res, err := ns.MultiQuery(ctx, turbopuffer.NamespaceMultiQueryParams{
	Queries: []turbopuffer.NamespaceMultiQueryParamsQuery{
		{RankBy: turbopuffer.NewRankByAnn("vector", queryVec), Limit: turbopuffer.LimitParam{Total: 50}},
		{RankBy: turbopuffer.NewRankByTextBM25("text", query), Limit: turbopuffer.LimitParam{Total: 50}},
	},
	RerankBy: turbopuffer.NewRerankByRrf(), // fused list in res.Results[0].Rows
})
```

Without `RerankBy`, results come back per-subquery in order. RRF's `rank_constant` defaults to 60. The recommended pipeline for serious search: LLM query rewriting → multi-query retrieval (~50-100 candidates each) → RRF → external re-ranker (Cohere, Voyage, etc.) → your own second-stage logic. Keep it all in one file (`search.go`). Evaluate with NDCG and a fixed query set; check ANN quality with `ns.Recall(...)` (compares ANN against exhaustive ground truth).

## Namespace operations

- `ns.Metadata(...)` — schema, `approx_row_count`, `approx_logical_bytes`, index status (`unindexed_bytes`), pinning/branching/sharding state. Billed as a zero-row query.
- `ns.HintCacheWarm(...)` — pre-warm the cache when a user opens your search UI, so their first query isn't cold. Free if already warm.
- `tpuf.NamespacesAutoPaging(ctx, turbopuffer.NamespacesParams{Prefix: turbopuffer.String("tenant-")})` — list namespaces (needs an API key with list permission).
- `ns.DeleteAll(...)` — delete the namespace and all documents. Irreversible; the name is immediately reusable.
- `ns.BranchFrom(...)` — instant copy-on-write clone, constant-time at any size, fully independent afterwards. Great for dev environments on production data, test pipelines, and pre-migration snapshots. Shares storage with the source, so it's not a backup.
- `ns.CopyFrom(...)` — full server-side copy; the tool for real backups (cross-region/cloud/org via `SourceRegion`/`SourceAPIKey`). There are **no automated backups** — schedule copies yourself if you need them.
- `ns.UpdateMetadata` with a pinning config — reserve dedicated compute + NVMe for a namespace. Worth it above ~10 QPS sustained; billed by GB-hours (64 GB minimum) instead of per-query.
- Sharding (beta, org-gated): only for namespaces beyond 500M docs / 1TB; `num_shards` is immutable after the first write.

## Multi-tenancy and permissions

Tenant isolation: one namespace per tenant. Document-level permissions within a namespace: store allowed `user_ids`/`group_ids` as array attributes (declare `[]uuid` explicitly — inferred string is slower and bigger) and filter with `Contains` from your auth layer. The inverted index makes membership filters cheap even with thousands of IDs. Model public documents as an explicit `is_public` bool rather than an empty permissions array — an empty array should mean *no* access, and the explicit flag is both safer and faster.

## Testing

Hit the real service with a unique namespace per test, deleted afterwards:

```go
func newTestNamespace(t *testing.T) turbopuffer.Namespace {
	t.Helper()
	tpuf := turbopuffer.NewClient()
	ns := tpuf.Namespace("test-" + uuid.NewString())
	t.Cleanup(func() {
		if _, err := ns.DeleteAll(context.Background(), turbopuffer.NamespaceDeleteAllParams{}); err != nil {
			var apierr *turbopuffer.Error
			if !errors.As(err, &apierr) || apierr.StatusCode != 404 {
				t.Logf("deleting test namespace: %v", err)
			}
		}
	})
	return ns
}
```

For testing against real data, `BranchFrom` a production namespace and delete the branch afterwards. For a harder boundary, use a separate turbopuffer organization for CI.

## Ingestion at scale

- Writes are synchronous and durable; indexing is async. If the unindexed backlog exceeds 2 GiB, writes get HTTP 429 until indexing catches up.
- For backfills: set `DisableBackpressure: turbopuffer.Bool(true)`, write large batches concurrently (a couple of goroutines per CPU), and query with eventual consistency until indexed — strongly consistent queries error above the backlog limit while backpressure is off. It doesn't combine with patches or conditional writes.
- Run the backfill from the same cloud region; max ingest is >150 MB/s per namespace when batched and concurrent.
- Retries are naturally idempotent: upserts are by ID.

## Performance checklist

- Batch writes; never write single documents in a loop (1 WAL commit/s per namespace).
- Keep namespaces as small as the query patterns allow; split rather than filter.
- `Filterable: false` on large attributes you don't filter (raw chunk text, blobs).
- Restrict `IncludeAttributes` to what you need.
- Prefer u64 or UUID document IDs over long strings.
- Fewer vector dimensions and smaller dtypes are faster: `[N]i8` > `[N]f16` > `[N]f32`. Models with quantization-aware training (voyage-4 family, embed-v4, qwen3) lose almost nothing at i8.
- Avoid frequently patching documents with large attributes — patch currently reads all attributes of the document. Store >10 KB payloads in a sibling namespace keyed by the same ID.
- Warm the cache ahead of user interaction; use eventual consistency where freshness doesn't matter.
- Keep first-stage `rank_by` simple (retrieve 100-1,000 candidates), do clever ranking in your own second stage.

## Limits that matter

Per namespace: 500M docs / 1TB unsharded (256 shards × that with sharding); 2 vector columns (fixed at creation); 10,752 max dense dimensions; 1,024 attribute names; 16 concurrent queries (17th waits up to 800ms, then 429 — aggregations count 4×, exact kNN 2×); ~5k QPS (read replicas raise it). Per request: 512 MB writes; `limit.total` ≤ 10k; 16 subqueries per multi-query; 256 computed attributes; full-text query ≤ 1,024 chars. Per document: 64 MiB total; 8 MiB per attribute value; 4 KiB per filterable value. Full table: https://turbopuffer.com/docs/limits — most limits can be raised on request.

## Gotchas

- **Query responses only include `id` and `$dist` by default.** Ask for attributes via `IncludeAttributes`; vectors are omitted unless requested.
- **Auto-inference locks in types.** First write wins; `uint`, `uuid`, `datetime`, and non-default vectors must be declared in the schema or they're inferred wrong with no in-place fix.
- **`DistanceMetric` is required** on every write to a namespace with vectors, and must not change.
- **FTS/regex/glob/fuzzy attributes default to non-filterable.** Set `Filterable: turbopuffer.Bool(true)` if you also filter on them.
- **Enabling a new index returns HTTP 202** on queries that need it until it's built.
- **Strong consistency has a ~10ms floor; eventual can be ~1h stale** after massive writes (>128 MiB unindexed).
- **Conditional writes on missing documents succeed unconditionally** — the condition only gates existing documents.
- **Billing multipliers:** indexed attributes cost logical size × index count (filterable + FTS = 200%); non-filterable 50%; conditional/filter writes add query cost.
- The docs' Go snippets use `param.NewOpt(true)` without showing the import; use `turbopuffer.Bool/Int/String` instead.

## When to reach for reference docs

Every docs page is fetchable as clean markdown: `https://turbopuffer.com/docs/<page>.md` (e.g. `/docs/query.md`, `/docs/write.md`, `/docs/fts.md`), index at `https://turbopuffer.com/llms.txt`, everything in one file at `https://turbopuffer.com/llms-full.txt`. The Go SDK surface is best checked with `go doc github.com/turbopuffer/turbopuffer-go/v2` (constructors are exhaustive there; the web docs are Python-first). Don't guess constructor or field names — look them up. Native embedding (private beta), CMEK, private networking, BYOC, and audit logs are Enterprise/plan-gated features; point the user at the docs and turbopuffer support for those.
