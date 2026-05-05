# Lexicon

Lexicon is the schema language. Every Lexicon file is JSON addressed by an **NSID** (a reverse-DNS identifier you control, e.g. `com.example.fooBar`). It defines records, XRPC endpoints, event stream messages, or OAuth scope bundles.

## File structure

```json
{
  "lexicon": 1,
  "id": "com.example.status",
  "description": "A user's current status emoji.",
  "defs": {
    "main": {
      "type": "record",
      "key": "tid",
      "record": {
        "type": "object",
        "required": ["text", "createdAt"],
        "properties": {
          "text":      { "type": "string", "maxLength": 280, "maxGraphemes": 140 },
          "createdAt": { "type": "string", "format": "datetime" }
        }
      }
    }
  }
}
```

- `lexicon`: always `1`.
- `id`: the NSID. Must match the file path (`com/example/status.json` for `com.example.status`).
- `defs`: map of named definitions. The optional `main` def is the file's "primary" type.
- Other defs are referenced from `main` or from other Lexicons via `ref`.

## Primary types (kinds of `defs` entries)

| Type | Purpose | Required fields |
|---|---|---|
| `record` | Document stored in a repo | `key`, `record` |
| `query` | XRPC GET endpoint | none (optional `parameters`, `output`) |
| `procedure` | XRPC POST endpoint | none (optional `parameters`, `input`, `output`) |
| `subscription` | WebSocket event stream | `message` (a union) |
| `permission-set` | OAuth scope bundle | `title`, `detail`, `permissions` |

`record.key` is a record key type: `tid` (default), `nsid`, `literal:<value>` (single-record collections like `app.bsky.actor.profile` use `literal:self`), or `any`.

## Field types

Concrete:

- `boolean`
- `integer` (signed 64-bit; cap at 53 bits if you care about JS)
- `string` (with optional `maxLength` in bytes, `maxGraphemes` for human-perceived length, `format`, `enum`)
- `bytes` (with optional `maxLength`)
- `cid-link`
- `blob` (with optional `accept` MIME patterns, `maxSize`)

Containers:

- `array` (`items`, optional `minLength`/`maxLength`)
- `object` (`properties`, optional `required`, `nullable`)
- `params` (HTTP query string only -- properties limited to boolean/integer/string and their arrays)

Meta:

- `ref` (`ref: "com.example.foo#bar"`) -- link to another def.
- `union` -- multiple possible types, discriminated by `$type`. Variants must be objects or records. Optional `closed: true` rejects unknown variants.
- `unknown` -- any data object; may include a `$type`.
- `token` -- a named symbolic value with no payload (used as enum tags via `ref`).

## String formats

- `at-identifier` (DID or handle), `at-uri`, `cid`, `did`, `handle`, `nsid`, `tid`, `record-key`, `uri`, `language`
- `datetime` -- RFC 3339, capital `T`, timezone required, `Z` preferred. Whole seconds minimum, fractional seconds OK.

## The `$type` discriminator

Required on:

- Every record's top-level object.
- Every variant inside a `union`, except subscription messages where the wrapper handles it.
- Every blob object.

Don't include `$type` on `ref` objects pointing at object types -- it's implied by the `ref`.

Field names starting with `$` are reserved for protocol use. Always ignore unknown `$`-prefixed fields.

## NSID rules (recap)

- ASCII only. 3+ segments, ≤317 chars total. Domain authority ≤253 chars, segments 1-63 chars.
- Domain part: letters, digits, hyphens (no leading/trailing hyphen per segment). Lowercase normalised.
- Name segment: alphanumeric, no hyphens, cannot start with a digit. Case-sensitive (don't normalise).
- Records: singular noun (`post`, not `posts`).
- XRPC methods: `verbNoun` (`getPost`, `createPost`, `searchActors`).
- Subscription messages: prefix with `#` in the lexicon (`#commit`, `#identity`).
- A trailing `*` is valid as a glob in scope strings (`com.example.*`).

## Validation modes

PDSes pick one of three modes for record writes; the default is **optimistic**:

- **Explicit required** -- record must validate against a known Lexicon, otherwise reject.
- **Explicit none** -- no Lexicon validation (data model rules still apply).
- **Optimistic (default)** -- validate if the Lexicon is known; accept if not (fail-open).

Your indexer should plan for **unknown fields** (ignore them) and **unknown record types** (skip). Don't crash on either.

## Evolution rules

These are load-bearing -- get this wrong once and you have a permanent migration headache.

You **can**:

- Add new optional fields.
- Add new record types under the same NSID prefix.
- Add new variants to an open union.

You **cannot**:

- Add a required field.
- Remove a non-optional field.
- Rename a field.
- Change a field's type.
- Tighten a constraint (`maxLength: 500` -> `maxLength: 280`).
- Loosen a constraint (`maxLength: 280` -> `maxLength: 500`).

Anything in the second list means a new NSID. Plan accordingly: name experimental schemas with `.temp.` or `.unspecced.` in the path (`com.example.temp.foo`) until they're stable. Major breaking redesigns conventionally get a `V2`/`V3` suffix.

Conventions and design patterns (pagination, hydrated views, sidecars, naming) live in [`lexicon-style.md`](lexicon-style.md).

## Authoring tips

- One Lexicon per file, named after the NSID. Layout on disk mirrors the NSID hierarchy: `lexicons/com/example/feed/post.json`.
- Put shared defs in `*.defs` Lexicons (`com.example.feed.defs`).
- Always include `description` fields -- they show up in generated client docs.
- Use `maxGraphemes` not just `maxLength` for human-facing text -- bytes lie.
- For input/output bodies that aren't JSON, use the encoding override:
  ```json
  "input":  { "encoding": "image/*" },
  "output": { "encoding": "application/vnd.ipld.car" }
  ```
- Authority is rooted in DNS control of the domain. Eventually schemas will be discoverable via `_lexicon` TXT records and `com.atproto.lexicon.schema` records under the authority DID -- design as if that's already the case.

## Worked example: a query endpoint

```json
{
  "lexicon": 1,
  "id": "com.example.getStatus",
  "defs": {
    "main": {
      "type": "query",
      "description": "Get the current status for an actor.",
      "parameters": {
        "type": "params",
        "required": ["actor"],
        "properties": {
          "actor": { "type": "string", "format": "at-identifier" }
        }
      },
      "output": {
        "encoding": "application/json",
        "schema": {
          "type": "object",
          "required": ["status"],
          "properties": {
            "status": { "type": "ref", "ref": "com.example.status" }
          }
        }
      },
      "errors": [
        { "name": "NotFound", "description": "No status found for this actor." }
      ]
    }
  }
}
```

## Worked example: a subscription

```json
{
  "lexicon": 1,
  "id": "com.example.subscribeStatuses",
  "defs": {
    "main": {
      "type": "subscription",
      "parameters": {
        "type": "params",
        "properties": {
          "cursor": { "type": "integer" }
        }
      },
      "message": {
        "schema": {
          "type": "union",
          "refs": ["#status", "#info"]
        }
      }
    },
    "status": {
      "type": "object",
      "required": ["seq", "actor", "status"],
      "properties": {
        "seq":    { "type": "integer" },
        "actor":  { "type": "string", "format": "did" },
        "status": { "type": "string" }
      }
    },
    "info": {
      "type": "object",
      "required": ["name"],
      "properties": {
        "name":    { "type": "string", "knownValues": ["OutdatedCursor"] },
        "message": { "type": "string" }
      }
    }
  }
}
```
