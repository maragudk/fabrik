# Identity: DIDs, handles, AT URIs

## DIDs

Two methods are blessed by atproto:

- `did:plc:<id>` -- self-authenticating, default for new accounts. Resolved via the PLC directory at `https://plc.directory/<did>`.
- `did:web:<hostname>` -- hostname-only (no paths). Resolved via `https://<hostname>/.well-known/did.json`.

Format constraints:

- Starts `did:` lowercase, then a method (lowercase letters), then a method-specific identifier.
- ASCII letters, digits, and `._:%-`. Case-sensitive.
- Cannot end in `:`. Percent-encoding requires two hex chars after `%`.
- Hard max 2048 chars; prefer ≤64.
- No query (`?`) or fragment (`#`) sections in DIDs themselves.

Reference regex: `/^did:[a-z]+:[a-zA-Z0-9._:%-]*[a-zA-Z0-9._-]$/`.

### What you extract from a DID document

After resolving, you care about three things:

| What | Where |
|---|---|
| Handle | First syntactically valid `at://...` entry in `alsoKnownAs` |
| Signing key | `verificationMethod` entry whose `id` ends in `#atproto`, `type: Multikey`, `publicKeyMultibase` |
| PDS | `service` entry whose `id` ends in `#atproto_pds`, `type: AtprotoPersonalDataServer`, `serviceEndpoint` is an HTTPS URL |

Labelers add another service entry whose `id` ends in `#atproto_labeler` and a verification method ending in `#atproto_label`.

### Multikey encoding (signing keys)

Public keys in DID documents use multikey: compressed point bytes, prefixed with a varint codec (`[0x80, 0x24]` for P-256, `[0xE7, 0x01]` for K-256), base58btc-encoded with a `z` prefix.

A legacy format (`EcdsaSecp256r1VerificationKey2019`, `EcdsaSecp256k1VerificationKey2019` with uncompressed base58btc points) exists -- accept it but don't emit it.

### Resolution failure modes

Distinguish:

- Invalid DID syntax (reject before any network call).
- Unsupported method (we only support `plc` and `web`).
- Network failure / unreachable (retry with backoff).
- DID document parse failure / missing required fields (treat as resolution failure).

## Handles

DNS hostnames. Format:

- ASCII, ≤253 chars total.
- 2+ segments separated by `.`. Each segment 1-63 chars.
- Letters, digits, hyphens. No leading/trailing hyphen per segment.
- TLD cannot start with a digit.
- Case-insensitive; normalise to lowercase.

Reserved TLDs: `.alt`, `.arpa`, `.example`, `.internal`, `.invalid`, `.local`, `.localhost`, `.onion`. `localhost` is OK only for development.

Reference regex: `/^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$/`.

### Resolution

Two methods. Try DNS first.

1. **DNS TXT** -- record at `_atproto.<handle>` with content `did=<did>`.
   ```
   _atproto.markus.example.com. IN TXT "did=did:plc:abc123..."
   ```
2. **HTTPS well-known** -- `GET https://<handle>/.well-known/atproto-did` returns the DID as plaintext (`Content-Type: text/plain`, 2xx status).

### Bidirectional verification (mandatory)

Resolving a handle gives you a DID. **Do not trust the handle until you also resolve the DID and confirm `alsoKnownAs` contains the handle.** Otherwise anyone can put a DNS record claiming any DID.

Order: handle -> DID (DNS or well-known) -> DID document -> check the handle is listed in `alsoKnownAs`.

## AT URIs

Format: `at://AUTHORITY[/COLLECTION[/RKEY]]`.

```
at://did:plc:vwzwgnygau7ed7b7wt5ux7y2/app.bsky.feed.post/3k5nobkf2w72g
at://markus.example.com/app.bsky.feed.post/3k5nobkf2w72g
```

- Authority: DID or handle.
- Collection: a normalised NSID.
- RKEY: a valid record key.

Notes:

- Handle-form URIs are **not durable** -- handles change. Store DID-form URIs.
- Not WHATWG URL-compliant (DIDs contain unencoded colons). You need a parser, not the stdlib.
- No query/fragment in current usage.
- Max 8 KB.
- Normalise: lowercase scheme and handle, no trailing slash, no unnecessary percent-encoding.

## NSIDs

Reverse-DNS. See `lexicon.md` for full rules. The short version:

- 3+ segments. Domain authority is reverse-DNS; final segment is the schema name.
- Records: singular noun. XRPC methods: `verbNoun`.
- Authority is rooted in DNS control. You "own" `com.example.*` if you control `example.com`.

## TIDs

13-character base32-sortable timestamps used as default record keys.

Layout (64-bit integer):

- Top bit: always 0.
- Next 53 bits: microseconds since UNIX epoch.
- Final 10 bits: random clock identifier (collision avoidance).

Encoding alphabet: `234567abcdefghijklmnopqrstuvwxyz`. Always 13 chars, no padding.

Reference regex: `/^[234567abcdefghij][234567abcdefghijklmnopqrstuvwxyz]{12}$/`.

Don't trust them as creation timestamps and don't assume global uniqueness. Generators must be monotonic per-process and use a random clock id.

## Record keys

A record key (rkey) identifies a record within a collection on a single repo. The tuple `(did, collection, rkey)` is unique; `(did, rkey)` alone is not.

Types (matching the `key` field in a `record` Lexicon):

| Type | Use |
|---|---|
| `tid` | Default. Monotonic timestamp identifiers. |
| `nsid` | When the rkey is itself a Lexicon NSID. |
| `literal:<value>` | Single-record collections. Most common: `literal:self` for profile-style records. |
| `any` | Free-form. URI-safe characters only. |

Syntax (any string-typed key):

- Allowed chars: alphanumeric, `.-_:~`.
- 1-512 chars. Cannot be `.` or `..`.
- Case-sensitive.
- Must be a valid URI path component.
- Recommended: lowercase, ≤80 chars.
