---
name: atproto
description: Guide for building on the AT Protocol (the "atmosphere") -- authoring Lexicons, building app views, consuming the firehose, working with identity (DIDs, handles), repositories, records, XRPC endpoints, and OAuth. Use this skill whenever the user is building anything on atproto/Bluesky/the atmosphere -- writing Lexicon JSON, calling com.atproto.* or app.bsky.* endpoints, parsing AT URIs (`at://...`), DIDs (`did:plc:...`, `did:web:...`), handles, TIDs, the indigo Go SDK (`github.com/bluesky-social/indigo`), the firehose / `subscribeRepos`, MSTs, CAR files, DAG-CBOR/DRISL, app views, feed generators, labelers, or PDS interactions. Triggers even if the user doesn't say "atproto" -- words like "lexicon", "PDS", "app view", "firehose", "did:plc", or `at://` URIs are enough.
license: MIT
---

# AT Protocol (atproto)

A guide for building on atproto -- the protocol behind Bluesky and the broader atmosphere of interoperable apps. This file is the overview and a router; deep details live in `references/`.

## Mental model

atproto is a federated protocol where users own a signed, content-addressed data **repository** that any service can replicate. Apps are mostly **app views** -- services that consume the network firehose, validate records against a **Lexicon** schema, index them, and expose a read API. Writes go to the user's PDS via XRPC.

Five concepts to keep in your head:

- **DIDs** identify accounts permanently (`did:plc:...` or `did:web:...`).
- **Handles** are mutable, DNS-based usernames.
- **Repositories** are signed, content-addressed Merkle Search Trees of records held on a **PDS**.
- **Lexicons** are JSON schemas naming and validating records and HTTP endpoints, addressed by **NSID** (`com.example.fooBar`).
- **XRPC** is HTTP transport for Lexicon-defined endpoints; the firehose is the WebSocket variant.

## Service roles

Real systems are made of four roles. An app you build is usually #3.

1. **PDS (Personal Data Server)** -- hosts a user's repo, signing keys, blobs. Authenticates clients. One per user.
2. **Relay** -- subscribes to many PDSes' firehoses and aggregates into one stream. Optimisation, not source of truth.
3. **App View** -- subscribes to a relay, validates records, indexes them, exposes XRPC reads. Bluesky's timeline service is one. A "feed generator" is a thin specialised app view.
4. **Labeler** -- emits signed labels (moderation/badge metadata) on URIs. Has its own DID and signing key.

## What to read next

This SKILL.md is intentionally thin. For anything beyond a high-level question, jump to the right reference:

| You are doing | Read |
|---|---|
| Authoring a Lexicon (records, queries, procedures, subscriptions) | [`references/lexicon.md`](references/lexicon.md) |
| Working with DIDs, handles, AT URIs, NSIDs, TIDs, record keys | [`references/identity.md`](references/identity.md) |
| Calling XRPC endpoints, handling errors, auth, proxying | [`references/xrpc.md`](references/xrpc.md) |
| Reading repos, commits, MSTs, CAR files, the data model | [`references/repository.md`](references/repository.md) |
| Consuming the firehose / `subscribeRepos`, event framing | [`references/firehose.md`](references/firehose.md) |
| OAuth client implementation specifics | [`references/oauth.md`](references/oauth.md) |
| Designing an app view end-to-end (the most common task) | [`references/app-view.md`](references/app-view.md) |
| Picking a Go package from indigo, code sketches | [`references/indigo-go.md`](references/indigo-go.md) |

If a question spans several topics, start with `app-view.md` -- it stitches the others together.

## Default stack for Markus's Go projects

- **Identity, syntax, repo, lexicon, XRPC, OAuth**: the indigo Go SDK (`github.com/bluesky-social/indigo`). See `references/indigo-go.md`.
- **Indexing storage**: SQLite or Postgres. Persist the firehose cursor in the same database.
- **Serving HTML**: gomponents + Datastar, per the existing fabrik skills.

## The most common gotchas

These bite people the first time they build anything on atproto:

- **Handles are not durable.** Always store DIDs as the primary identifier; cache handles separately and refresh on `#identity` events.
- **Lexicons can never tighten or loosen constraints after publication.** Add optional fields only; mint a new NSID for breaking changes.
- **Floats are not in the data model.** Use integers, or strings for fixed-point.
- **`$type` is required** on records, blobs, and union variants. Strict clients silently drop records without it.
- **TID timestamps are advisory.** Use your own `indexedAt` for ordering.
- **EXIF stripping on uploaded blobs is the client's job**, not the PDS's.
- **Bidirectional verification is mandatory** when resolving handles -- handle->DID, then DID->handle. Otherwise anyone can claim any handle.

## Spec index

<https://atproto.com/specs/atp> -- starting point for everything below.

| Spec | URL |
|---|---|
| Lexicon | <https://atproto.com/specs/lexicon> |
| Data model | <https://atproto.com/specs/data-model> |
| Repository | <https://atproto.com/specs/repository> |
| XRPC | <https://atproto.com/specs/xrpc> |
| Sync / firehose | <https://atproto.com/specs/sync> |
| Event stream framing | <https://atproto.com/specs/event-stream> |
| OAuth | <https://atproto.com/specs/oauth> |
| DIDs | <https://atproto.com/specs/did> |
| Handles | <https://atproto.com/specs/handle> |
| NSIDs | <https://atproto.com/specs/nsid> |
| TIDs | <https://atproto.com/specs/tid> |
| Record keys | <https://atproto.com/specs/record-key> |
| AT URI | <https://atproto.com/specs/at-uri-scheme> |
| Blobs | <https://atproto.com/specs/blob> |
| Labels | <https://atproto.com/specs/label> |
| Cryptography | <https://atproto.com/specs/cryptography> |
| Permissions | <https://atproto.com/specs/permission> |
| Accounts | <https://atproto.com/specs/account> |

Worked examples: [Statusphere tutorial](https://atproto.com/guides/statusphere-tutorial) (TS), [indigo](https://github.com/bluesky-social/indigo) services (Go), [Bluesky's canonical Lexicons](https://github.com/bluesky-social/atproto/tree/main/lexicons) (the best style reference).
