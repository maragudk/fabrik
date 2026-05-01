# Firehose / event streams

WebSocket streams of repository events. The canonical endpoint is `com.atproto.sync.subscribeRepos`, exposed by both PDSes (just their accounts) and relays (aggregated). Event streams in general are described by the Lexicon `subscription` type.

## Connection

Upgrade an HTTP GET to WebSocket:

```
GET /xrpc/com.atproto.sync.subscribeRepos?cursor=<seq> HTTP/1.1
Host: relay.example.com
Connection: Upgrade
Upgrade: websocket
```

Use `wss://` over the open internet. `ws://` is OK only for local dev.

Connection-time errors (HTTP, before upgrade):

| Code | Meaning |
|---|---|
| 405 | Non-GET request |
| 426 | Missing Upgrade header |
| 429 | Too many requests |
| 501 | WebSocket not supported |

## Frame format

Each binary WebSocket frame is **two concatenated DRISL-CBOR objects**:

1. **Header** -- `{op, t}`:
   - `op`: integer. `1` for a regular message, `-1` for an error.
   - `t`: string. Message type in short form, e.g. `"#commit"`. Omitted on error.
2. **Payload** -- shape depends on `op` and `t`.

Error payloads:

```cbor
{ "error": "ConsumerTooSlow", "message": "..." }
```

The connection is closed immediately after an error frame. If a frame fails to parse, **drop the connection** -- never skip frames.

## Sequence numbers and replay

Streams have monotonically increasing sequence numbers. Pass the last seen `seq` as `cursor` to resume:

| Cursor | Behaviour |
|---|---|
| Omitted | Start from the live tip. |
| Within rollback window | Replay then go live. |
| Outside window | Server sends `info` ("OutdatedCursor"), then full window from start. |
| Future / invalid | Error frame, connection closed. |

Sequence numbers fit in 53 bits (JavaScript-safe). Rollback window varies (hours to days); plan for both replay and full resync.

## Message types on `subscribeRepos`

### `#commit`

A new repo commit. Contains a CAR slice (the diff from the previous commit) plus an `ops` list:

```
{
  seq, rebase, tooBig, repo, commit, prev, rev, since,
  blocks: <CAR bytes>,
  ops: [ { action: "create" | "update" | "delete", path: "<collection>/<rkey>", cid?: <CID> }, ... ]
}
```

Walk `ops` to find records you care about, then look up the record bytes in the CAR slice.

### `#identity`

DID document or handle changed for an account. Re-resolve the DID and update your cached handle.

```
{ seq, did, time, handle?: "<new handle>" }
```

### `#account`

Hosting status changed:

```
{ seq, did, time, active: bool, status?: "takendown" | "suspended" | "deleted" | "deactivated" }
```

When `active: false`, stop redistributing the account's content (records, blobs, transformed views). For `deleted`, drop your stored data per your retention policy.

### `#sync`

An assertion of current state, used for clarification or recovery. Contains the commit block but not a diff -- if you need the records you fetch them separately.

## Consumer responsibilities

- **Persist your cursor** transactionally with whatever you index. Restart-safe.
- **Process in order** within a repo. Cross-repo ordering doesn't matter.
- **Validate signatures** on commits if you care -- requires the signing key from the current DID document. Many indexers skip this and trust the relay; that's a tradeoff.
- **Validate records** against your Lexicon (optimistic mode). Drop records that fail.
- **Honour `#account` and `#identity`** events promptly -- this is the only way handles and hosting status propagate.
- **Don't be slow.** Servers will disconnect slow consumers with a "too slow" error. If you can't keep up, buffer and process in a worker.

## Building your own subscription

If you author a Lexicon with `type: subscription`, the same framing applies:

- Header is `{op, t}` where `t` is `#<variant>` matching a union variant in your `message` schema.
- Sequence numbers are your responsibility -- mint them server-side.
- Define an `info` variant for events like outdated cursors.
- Document the rollback window in your Lexicon's `description`.
