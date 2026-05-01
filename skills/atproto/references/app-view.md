# Building an app view

This is the most common atproto app shape: subscribe to a relay's firehose, validate records against a Lexicon, index them in your own database, and expose XRPC reads. Writes go straight from clients to their PDS -- you never hold user credentials.

## Architecture

```
                       firehose                 your indexer            your XRPC reads
                          |                          |                          |
   PDSes  -- relay  -->  WebSocket subscribeRepos  -->  validator + DB write  --> SQLite/Postgres  --> /xrpc/com.example.*
                                                          |
                                                          +-- identity cache (DID -> handle, PDS, signing key)

   Writes:  client (with OAuth token) ---> user's PDS (com.atproto.repo.createRecord) ---> firehose ...
```

You don't run a PDS. You don't need to.

## End-to-end recipe

1. **Define your Lexicon(s).** Pick a domain you control, write JSON schemas for your record type(s) and your read endpoints, layout under `lexicons/<reverse-NSID>/`.
2. **Generate types and clients.** In Go, use indigo's `lexgen` to produce typed structs. In TS, `@atproto/lex-cli`.
3. **Subscribe to a relay's `subscribeRepos`** with a persistent cursor. For Bluesky's network, use `https://relay1.us-west.bsky.network` or run your own relay (jetstream is a lighter alternative if you're OK with JSON instead of CAR slices).
4. **Filter** for collections you care about. In each `#commit` message, walk `ops` and keep only those whose path starts with your NSID (`com.example.status/...`).
5. **Validate** the record against your Lexicon. Use optimistic mode; drop records that fail.
6. **Resolve identity** for the author DID. Cache aggressively -- DIDs are stable. Cache handles separately and refresh on `#identity` events.
7. **Index** into your own database. Store DIDs, not handles. See "Storage" below.
8. **Handle `#account` events** by hiding/dropping content from non-active accounts (`takendown`, `suspended`, `deleted`, `deactivated`).
9. **Handle `#identity` events** by invalidating the cached handle for the affected DID.
10. **Expose XRPC read endpoints** under your own NSID prefix (`com.example.getStatuses`, `com.example.getStatus`).
11. **Serve a public client metadata document** if your client uses OAuth.

Optional but normal:

- A web frontend (gomponents + Datastar fits Markus's stack) that calls your own XRPC reads.
- A login flow (OAuth) so users can write records via their PDS through your UI.
- A CDN proxy for blobs you reference.

## Storage

Your indexing database is private to your service. Any boring database will do. SQLite is fine well into the millions of records; Postgres is fine for everything.

Suggested table shape for a record collection:

| Column | Notes |
|---|---|
| `author_did` | TEXT, primary key part. The user's DID. Don't denormalise the handle. |
| `rkey` | TEXT, primary key part. Together with `author_did` this is unique. |
| `cid` | TEXT. Record CID for verification / dedup. |
| `record` | JSON or TEXT. The validated record body. |
| `indexed_at` | TIMESTAMP, your wall clock. Use this for ordering -- not TIDs. |
| `created_at` | TIMESTAMP from the record's own `createdAt` field if it has one. |

Indexes:

- `(author_did, indexed_at DESC)` for per-user views.
- `(indexed_at DESC)` for global feeds.
- Whatever else your queries need.

A separate table for identity:

| Column | Notes |
|---|---|
| `did` | TEXT, primary key. |
| `handle` | TEXT. Refreshed on `#identity`. Nullable. |
| `pds` | TEXT. PDS endpoint URL. |
| `signing_key_multibase` | TEXT. From the `#atproto` verification method. |
| `active` | BOOLEAN. From `#account` events. |
| `status` | TEXT. `takendown` / `suspended` / etc. |
| `resolved_at` | TIMESTAMP. For cache TTL. |

Persist the firehose cursor in the same database, in the same transaction as the records you derive from a frame. That's how you stay restart-safe without losing or double-processing events.

## Backfill

A relay's rollback window is hours to days. If you're starting from cold:

- Subscribe with no cursor for live data.
- For historical data, use `com.atproto.sync.listRepos` and `com.atproto.sync.getRepo` per repo, walk the CAR file yourself, then switch to live with the seq from the moment you started.
- Or use a tool like indigo's `tap` (in TS, also a Go port available) which orchestrates this.

## Scaling notes (for later, not first)

- A single SQLite database is enough until you need horizontal scale. Don't pre-optimise.
- The firehose is one process; index in batches of N records per transaction.
- If your subscription falls behind too often, split the work: one subscriber writes raw frames to a queue, workers index from the queue. SQLite-as-a-queue or a cheap Postgres table works.
- Periodically reverify a sample of records against the live PDS to catch desync.

## Read API design

Your XRPC read endpoints live under your own NSID. Return data in the shape your UI wants -- you're not obliged to return raw records.

Conventions worth following:

- `getX` for single records, `listX` / `searchX` for collections.
- Cursor pagination as described in `xrpc.md`.
- Errors named in the Lexicon `errors` array.
- Don't accept user-controlled SQL fragments. Use the Lexicon `parameters` types.

## Writes

Your service does not write to user PDSes. The client does, holding their own OAuth token. Your part of the write path:

- Issue an OAuth client (publish client metadata, hold a key for confidential clients).
- After the user signs in, your client gets an access token bound to a DPoP key.
- The client calls `com.atproto.repo.createRecord` (or `putRecord`, `deleteRecord`, `applyWrites`) on the user's PDS, with their record validated against your Lexicon.
- The PDS commits, and the firehose carries it back to your indexer like any other record.

That's why your indexer must be optimistic -- you'll see your own writes flow through the same loop everyone else's do.
