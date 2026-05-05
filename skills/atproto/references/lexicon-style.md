# Lexicon style guide (Lexinomicon)

Conventions and design patterns for authoring Lexicons. `lexicon.md` covers the mechanics ("what's legal"); this file covers the conventions ("what's idiomatic"). When in doubt, copy [Bluesky's canonical Lexicons](https://github.com/bluesky-social/atproto/tree/main/lexicons).

> Source: [bluesky-social/atproto discussion #4245](https://github.com/bluesky-social/atproto/discussions/4245). It's a living draft -- check there for updates.

## Naming

Casing:

- Schema names, NSID name segments, field names: `lowerCamelCase`.
- API error names: `UpperCamelCase` (e.g. `NotFound`, `OutdatedCursor`).
- Fixed string values (`knownValues`, enum-ish constants): `kebab-case`.

Character set:

- Field names follow NSID name-segment rules: ASCII alphanumeric, no hyphens, can't start with a digit, case-sensitive.
- Field names starting with `$` are reserved for the protocol -- never define your own.

NSID name shapes:

- `record` -- singular noun: `post`, `like`, `profile`. Not `posts`.
- `query` -- `verbNoun`. Common verbs: `get`, `list`, `search` (full-text), `query` (filtering).
- `procedure` -- `verbNoun`. Common verbs: `create`, `update`, `delete`, `upsert`, `put`.
- `subscription` -- `subscribePluralNoun`: `subscribeLabels`, `subscribeRepos`.
- `permission-set` -- prefix with `auth`: `authBasic` (convention still settling).

Use `.temp.` or `.unspecced.` infixes in the NSID for experimental/unstable schemas (`com.example.temp.foo`). Don't invent your own marker like `experimental`.

Avoid generic names that clash with language keywords: `default`, `length`, `type`, etc.

## NSID grouping

- Group related schemas under a shared prefix: `app.bsky.feed.*`, `app.bsky.graph.*`. Tiny apps can put everything under one group.
- Put shared definitions in a `*.defs` file (`app.bsky.feed.defs`). Deletion of any sibling Lexicon then doesn't invalidate references to the shared defs.
- Avoid name collisions between groups, schemas, and definitions:
    - Don't define both `app.bsky.feed` (as a record) and `app.bsky.feed.post` (treating `feed` as a group).
    - Don't have both `com.example.record#foo` and `com.example.record.foo` in the same namespace.

## Documentation

- Every `main` def gets a `description`. For API endpoints, mention auth: required, optional (and whether the response personalises), or none.
- Add `description` to anything ambiguous. Especially fields with generic names (`uri`, `cid`) -- always say *of what*.

## Field design

### Strings

- Specify `format` when one fits (`did`, `at-uri`, `cid`, `datetime`, `language`, `at-identifier`, ...).
- Strings without a `format` should almost always have a max length.
- For human-facing text, set both `maxGraphemes` (visual length) and `maxLength` (byte ceiling). Aim for ~10-20 bytes per grapheme.
- Don't redundantly specify `format` *and* length limits.

### Strings vs blobs

- `string` and `bytes` are for small, constrained data.
- For longer text, larger payloads, or anything resembling a document, use `blob`.

### Enums and tokens

- **Avoid `enum` sets.** They're closed; you can't add values without a breaking change.
- Prefer string fields with `knownValues` -- open by construction.
- `knownValues` entries can be plain strings or refs to a `token` (`com.example.defs#tokenOne`). Tokens are best for values whose meaning is subjective or likely to grow over time.
- See `com.atproto.moderation.defs#reasonType` (extensible) and `com.atproto.sync.defs#hostStatus` (constrained) for two stylistic poles.

### CIDs

- String form is the default -- use it for versioned references between records (`com.atproto.repo.strongRef`).
- Binary `cid-link` is for protocol-level mechanisms (firehose frames, MST nodes). Don't use it in app records.

### Booleans

Optional booleans should be phrased so `false` is the default and the common case. If results normally include `foo` but not `bar`, the params are `excludeFoo` (default `false`) and `includeBar` (default `false`) -- not `excludeBar` (default `true`).

### Identifying accounts

- API params taking an account: use `at-identifier` (handle or DID) so clients don't have to call `resolveHandle` first.
- Record fields referencing other accounts: always use `did`. Handles drift; DIDs don't.

### Reuse

- Versioned record references: `com.atproto.repo.strongRef`.
- Hydrated label arrays: `com.atproto.label.defs#label`.

## API endpoints

- Always specify `output` with an `encoding`, even when there's no meaningful response data. A safe default is `application/json` with an empty object schema.
- Don't expose user-controlled SQL or query DSL through `parameters`.

## Schema evolution

The cheap recap (full rules in `lexicon.md`):

- Don't mark a field `required` unless functionality genuinely depends on it. `required` is one-way.
- New `optional` fields can be added freely.
- Arrays should hold objects, not atomic values, even when only one field is needed today -- this leaves room for future context. An array of `{ "account": did }` ages better than an array of DIDs.
- Make unions **open** unless you have a hard reason to close them. Open unions are also the standard third-party extension point.
- Major breaking changes get a new NSID, conventionally suffixed `V2`/`V3`.

## Design patterns

### Pagination (queries)

Standard contract:

- Params: optional `limit` (integer) and optional `cursor` (string).
- Output: optional `cursor` (string) and a required array with a context-specific plural name (`posts`, `feeds`).
- First call has no `cursor`. If the response includes one, more results exist; pass it back to get the next page.
- `limit` is an *upper* bound. The server may return fewer (or zero) results while more remain. **Pagination ends when the response has no `cursor`**, not when the array is empty -- items can be filtered/tombstoned mid-stream.

### Subscriptions (sequenced backfill)

- Param: optional `cursor` (integer).
- Every core message includes a monotonically increasing `seq` (gaps allowed).
- No cursor: stream from now.
- Cursor present: server replays from that `seq` and continues live.
- Cursor in the future: error and close.
- Cursor too old (or `0`): server emits an info message named `OutdatedCursor`, then streams from the oldest available `seq`.

### Hydrated views

App view responses commonly bundle a record with derived data (CDN URLs, label arrays, viewer-specific state, aggregates). Two rules:

- **Embed the original record verbatim** -- a `record` field of the original type. Don't define a parallel "view" schema with a superset of fields. You'll forget to update one. Verbatim embedding also preserves off-schema extensions.
- **Group viewer-specific fields under a sub-object** (e.g. `viewer: { liked, muted }`). This keeps the schema usable for both anonymous and authenticated views, and makes it obvious which fields require auth.

A canonical "give me the hydrated view of this record (or these records)" endpoint is a good thing to expose.

### Sidecar records

To extend a record without breaking strong references to it:

- Define a separate record type in a different collection.
- Use the **same record key** as the record it augments (in the same repo).
- Sidecars can be authored by the original Lexicon designer or third parties; they can be mutated independently; they can be merged into hydrated views.

### Declaration / activation records

If your app modality needs a way to ask "is this account participating in *this* app?", define a known representative record type with a fixed record key (often a profile or declaration record, often empty). Creation = active in this modality; deletion = no longer active. Backfill services can then enumerate the modality's accounts cleanly.

This is a strongly recommended pattern for any new app modality.

### Rich text vs Markdown

- Short annotated text: use `app.bsky.richtext.facet`. The feature type system is an open union, so third parties can add new annotation kinds. See [Why RichText facets in Bluesky](https://www.pfrazee.com/blog/why-facets).
- Long-form text: use Markdown (or another full markup language) in a blob.
