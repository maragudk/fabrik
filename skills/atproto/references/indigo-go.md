# Go (indigo SDK)

The reference Go implementation lives at `github.com/bluesky-social/indigo`. It contains both services and libraries. For building your own app, you mostly use the libraries.

## Packages worth knowing

| Package | What it gives you |
|---|---|
| `atproto/syntax` | Parsers for `DID`, `Handle`, `NSID`, `TID`, `ATURI`, `RecordKey`. Use these instead of regex. |
| `atproto/identity` | `Directory` interface for resolving DIDs and handles. Bidirectional verification baked in. Has a caching wrapper. |
| `atproto/atcrypto` | K-256 / P-256 keys, signing, verification, multibase encoding. |
| `atproto/repo` | MST, commit objects, CAR reader/writer. |
| `atproto/lexicon` | Lexicon parser and runtime validator. |
| `atproto/atclient` | XRPC client. Handles auth, retries, headers. |
| `atproto/auth/oauth` | OAuth client (PKCE / PAR / DPoP). |
| `atproto/data` (sometimes `atdata`) | DRISL-CBOR encoding, JSON conversion. |
| `events` (top-level) | Firehose framing and event handling. |
| `api/atproto`, `api/bsky` | Generated types for the canonical Lexicons. |

## Code generation: lexgen

For your own Lexicons, generate Go types with the `lexgen` command in indigo. Layout your Lexicons mirroring the NSID hierarchy, then run lexgen pointing at the directory and a target package. Commit the generated code.

This gives you typed structs for records, request params, and response bodies, plus helpers to register them with the lexicon validator. Don't hand-write the structs.

## Sketches

The snippets below are illustrative. Cross-reference indigo's `cmd/` services for the working versions; package layouts shift over time.

### Resolve a handle to an identity (with bidirectional verification)

```go
import (
    "context"
    "github.com/bluesky-social/indigo/atproto/identity"
    "github.com/bluesky-social/indigo/atproto/syntax"
)

type identityResolver interface {
    Lookup(ctx context.Context, atid syntax.AtIdentifier) (*identity.Identity, error)
}

func resolve(ctx context.Context, dir identityResolver, raw string) (*identity.Identity, error) {
    atid, err := syntax.ParseAtIdentifier(raw)
    if err != nil {
        return nil, err
    }
    return dir.Lookup(ctx, *atid)
}
```

`identity.DefaultDirectory()` gives you a directory that does PLC + web resolution and bidirectional handle verification. Wrap it in a caching directory in production.

### Make an authenticated XRPC call

```go
import (
    "context"
    "github.com/bluesky-social/indigo/atproto/atclient"
)

type getTimelineResp struct {
    Cursor string  `json:"cursor"`
    Feed   []any   `json:"feed"`
}

func timeline(ctx context.Context, c *atclient.Client) (*getTimelineResp, error) {
    var out getTimelineResp
    err := c.Get(ctx, "app.bsky.feed.getTimeline", map[string]any{"limit": 50}, &out)
    return &out, err
}
```

### Subscribe to the firehose

In real code, use indigo's `events` package -- it handles framing, sync messages, the `#commit`/`#identity`/`#account` switch, and CAR slice parsing. The shape of your loop:

```go
import (
    "context"
    "github.com/bluesky-social/indigo/events"
)

type Indexer struct{ /* db, identity cache, ... */ }

func (ix *Indexer) HandleCommit(ctx context.Context, evt *events.RepoCommit) error {
    for _, op := range evt.Ops {
        // op.Action is "create" / "update" / "delete"
        // op.Path is "<collection>/<rkey>"
        // For non-deletes, fetch the record block from evt.Blocks (a CAR slice) by op.Cid.
        if !strings.HasPrefix(op.Path, "com.example.status/") {
            continue
        }
        // Validate against your Lexicon, then upsert into your DB.
    }
    return nil
}

func (ix *Indexer) HandleIdentity(ctx context.Context, evt *events.RepoIdentity) error {
    // Re-resolve evt.Did, update your identity cache.
    return nil
}

func (ix *Indexer) HandleAccount(ctx context.Context, evt *events.RepoAccount) error {
    // Update active/status. Hide content for !active.
    return nil
}
```

Wire those into `events.Subscribe` (or whichever helper the current indigo version exposes) with your relay URL and persisted cursor.

If you don't need raw CAR slices, **jetstream** (a separate service in the same ecosystem) emits the same firehose as JSON over WebSocket. It's friendlier for prototypes and many production indexers.

### Sign a JWT for service-to-service calls

```go
import (
    "github.com/bluesky-social/indigo/atproto/atcrypto"
)

// Load the signing key from your DID document (or wherever you store it).
priv, err := atcrypto.ParsePrivateMultibase(privMultibase)
if err != nil { /* ... */ }

// Use your JWT library of choice with the alg from the key (ES256K for k256, ES256 for p256),
// setting iss=<userDID>, aud=<targetServiceDID>#<service>, lxm=<NSID>, exp/iat/jti.
```

## Conventions for Markus's projects

Per the `go` skill:

- Application layout: `cmd/app`, `model`, `sqlite`, `http`, `html`, etc.
- Dependency injection via private interfaces on the receiving side.
- Tests with `maragu.dev/is`, real dependencies (no mocks for the firehose -- use a recorded fixture).
- Server-side rendered HTML with gomponents + Datastar.

A typical atproto app view in this style ends up with packages roughly like:

| Package | Role |
|---|---|
| `cmd/app` | Entrypoint. Wires firehose subscriber, indexer, HTTP server. |
| `model` | Domain types: `Status`, `Author`, `ATURI`, etc. Aliases over `syntax.DID` where useful. |
| `sqlite` | Schema, migrations, queries. Persists records and firehose cursor. |
| `firehose` | Subscribes to the relay, validates, calls into `sqlite`. |
| `identity` | Caching wrapper around `atproto/identity`. |
| `xrpc` | Your own `com.example.*` read endpoints. |
| `http` | Web UI (HTML pages, static assets). |
| `html` | gomponents views. |

Test fixtures are easiest as recorded firehose frames -- save real `subscribeRepos` traffic to a file and replay it in tests.

## When in doubt

Read indigo's services. The most useful as references:

- `cmd/relay` -- a working relay implementation.
- `cmd/palomar` -- fulltext search; a real app view.
- `cmd/hepa` -- automod bot; firehose consumer doing per-record work.
- `cmd/rainbow` -- firehose fan-out; helpful if you want to broadcast to many subscribers.

These will be more current than any code snippet here.
