# Repositories, the data model, and CAR files

A repo is a signed, content-addressed Merkle Search Tree of records belonging to one account.

## Data model

Records and messages use one model with two encodings:

- **DRISL-CBOR** (a strict normalised CBOR subset, successor to DAG-CBOR) for binary / signed / hash-linked.
- **JSON** for HTTP bodies and developer-facing APIs.

Type mapping:

| Lexicon | JSON | CBOR |
|---|---|---|
| `null` | `null` | major 7 special |
| `boolean` | bool | major 7 special |
| `integer` | number (signed 64-bit; cap at 53 bits if you care about JS) | majors 0/1 |
| `string` | UTF-8 string | major 3 |
| `bytes` | `{"$bytes": "<base64>"}` | major 2 |
| `cid-link` | `{"$link": "<base32 cid>"}` | tag 42 |
| `array` | array | major 4 |
| `object` | object (string keys only) | major 5 |
| `blob` | `{"$type": "blob", ...}` | map with `$type: blob` |

**Floats are not allowed.** Round-tripping floats through hash-addressed storage is unreliable, so they were dropped. Use integers, or strings for fixed-point.

Field names starting with `$` are reserved for protocol use. Ignore unknown `$`-prefixed fields.

`null` is distinct from missing. Setting a field to `null` and omitting it are not the same. Neither equals `false`/`0`/`""`.

## Blob objects

```json
{
  "$type": "blob",
  "ref":   { "$link": "bafkreig..." },
  "mimeType": "image/jpeg",
  "size": 12345
}
```

- `ref` is a CID with the **raw codec** (0x55), not DRISL.
- A deprecated legacy form (`{"cid": "<string>", "mimeType": "..."}`) exists -- read it but never write it.

## CIDs

Blessed CID format in atproto:

- Version 1 (0x01).
- Codec: DRISL (0x71) for data; raw (0x55) for blobs.
- Hash: SHA-256 (0x12), 256 bits.
- String form: base32 with `b` prefix.

CIDs appear as `cid-link` fields, as strings with `format: cid`, or as `ipld://` URIs.

## Repository structure

Path format inside a repo: `<collection>/<rkey>`. Both must be syntactically valid (see `lexicon.md`, `identity.md`).

The repo is a **Merkle Search Tree** with:

- Keys: full repo paths.
- Values: record CIDs (one MST leaf per record).
- Fanout 4, derived from leading zeros in the SHA-256 of the key, taken in 2-bit chunks.

This gives deterministic structure: any service that has the records can rebuild the tree byte-for-byte. Practical scale: up to single-digit millions of records per repo.

## MST node format

Each node:

- `l`: link to left subtree (CID or null).
- `e`: ordered array of entries, each with:
  - `prefixlen`: bytes shared with the previous entry's key.
  - `keysuffix`: remaining key bytes.
  - `v`: record CID.
  - `t`: link to right subtree of this entry (CID or null).

Keys use prefix compression for efficiency. The whole structure is reproducible from `(key, cid)` pairs alone.

## Commits

A commit is the signed root:

```
{ did, version: 3, data: <CID of MST root>, rev: <TID>, prev: <CID|null>, sig }
```

- `rev` is a TID-formatted revision string, monotonically increasing.
- `prev` links the previous commit (or null on the genesis commit).
- `sig` is the DRISL-encoded unsigned commit, SHA-256-hashed, then signed with the account's current signing key.

Every record write -- create, update, or delete -- produces a new commit.

## CAR files

Repositories export as **CAR v1** files:

- Header.
- Commit object first.
- MST nodes in pre-order (parent before children).
- Records interleaved between nodes.

Stream-friendly: you can verify and process without buffering the whole file.

CAR slices used in firehose `#commit` messages contain just the new commit, modified MST nodes, and affected records -- enough to apply a diff against your local copy without retransmitting the whole repo.

## Verifying integrity

When importing a CAR:

- Every record must be reachable from the commit's MST root.
- Every block's CID must match its content.
- The commit signature must verify against the current signing key from the DID document.
- No blocks for other accounts; no orphans.

If any check fails, reject the whole import. Don't try to partially-apply.

## Practical implications for indexers

- Don't try to mirror entire repos unless you have a specific reason.
- Index only the collections and fields you actually query.
- Store record CIDs alongside the data so you can verify against the firehose later.
- Use the firehose `ops` list to drive your indexer -- you don't usually need to walk the MST yourself.
