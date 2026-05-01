# XRPC

XRPC is HTTP transport for Lexicon-defined endpoints. Path is always `/xrpc/<NSID>`. Two flavours:

- **Query** -- HTTP GET. Cacheable. No mutation.
- **Procedure** -- HTTP POST. May mutate.

The NSID in the path matches the `id` of a Lexicon whose primary type is `query` or `procedure`. Subscriptions also live under `/xrpc/<NSID>` but use WebSocket -- see `firehose.md`.

## Parameter encoding

Lexicon `parameters` (a `params` type) become URL query parameters:

- Repeated keys for arrays: `?lang=en&lang=da`.
- Booleans as unquoted `true`/`false` strings.
- Strings unquoted.
- Always send default values explicitly so caches stay coherent.

Procedure inputs go in the body, content-type per the Lexicon (defaults to JSON).

## Content types

Default is `application/json`, following atproto's data model JSON encoding (see `repository.md`).

For non-JSON, the Lexicon specifies an `encoding`:

- Concrete: `application/vnd.ipld.car`, `image/png`.
- Pattern: `image/*` accepts any image MIME.

## Error responses

JSON body, even on errors:

```json
{ "error": "ErrorName", "message": "human-readable detail" }
```

- `error` is an ASCII type identifier defined in the Lexicon's `errors` array. Use it for client logic.
- `message` is for humans. Don't parse it.

Standard status codes:

| Code | Meaning |
|---|---|
| 200 | Success |
| 400 | Bad request (validation, malformed body) |
| 401 | Unauthorized (must include `WWW-Authenticate`) |
| 403 | Forbidden |
| 404 | Not found |
| 413 | Payload too large |
| 429 | Rate limited (may include `Retry-After`) |
| 500 | Internal error |
| 501 | Not implemented |
| 502 / 503 / 504 | Upstream / unavailable |

Clients should retry on 429 (honouring `Retry-After`) and 5xx with randomised exponential backoff.

## Authentication

| Mechanism | When |
|---|---|
| OAuth | Default for third-party clients. PKCE + PAR + DPoP all mandatory. See `oauth.md`. |
| App passwords | Legacy `com.atproto.server.createSession` / `refreshSession`. Token is opaque -- don't rely on JWT internals. App passwords cannot delete the account. |
| Admin token | HTTP Basic, username `admin`. PDS admin endpoints. |
| Inter-service JWT | Short-lived JWT signed by the user's atproto signing key. For service-to-service. |

### Inter-service JWT claims

| Claim | Meaning |
|---|---|
| `alg` | `ES256K` (k256) or `ES256` (p256) |
| `typ` | `JWT` |
| `kid` | Key identifier; defaults to `#atproto` |
| `iss` | User account DID |
| `aud` | Target service DID, with optional fragment (e.g. `did:web:bsky.app#bsky_appview`) |
| `exp`, `iat` | UNIX timestamps |
| `lxm` | NSID of the authorized endpoint (binds the JWT to one method) |
| `jti` | Unique nonce -- replay prevention |

Receiving services must verify `aud` matches their own DID and the fragment matches their service kind.

### JWT type separation (legacy session JWTs)

The `typ` header distinguishes:

- Access tokens: `at+jwt` (RFC 9068).
- Refresh tokens: `refresh+jwt`.

## Service proxying

Set `atproto-proxy: <did>#<service-name>` and the user's PDS will forward the request to that service, signing an inter-service JWT for you. Useful when your client only knows the user's PDS but wants to talk to an app view.

Constraints:

- Only `/xrpc/...` paths.
- The target service must have a resolvable DID with the right service entry.
- The user must be authenticated to their PDS.
- The PDS's rate limits still apply.

## Other useful headers

| Header | Purpose |
|---|---|
| `Authorization` | Credentials |
| `Content-Type` | Body type |
| `atproto-proxy` | Route to another service |
| `atproto-accept-labelers` | Comma-separated DIDs of labelers to apply |
| `atproto-content-labelers` | Response: which labelers were applied |

## Cursor pagination

Standard pattern across all list endpoints:

1. First call: omit `cursor`.
2. Response includes `cursor` (opaque string) if there's more.
3. Next call: include the cursor; keep all other params identical.
4. Stop when the response omits `cursor`.

Don't try to interpret cursors -- they're opaque.

## Blobs

Upload through `com.atproto.repo.uploadBlob`:

- Required headers: `Content-Type` (the actual type), `Content-Length`.
- Server sniffs content; rejects on size mismatch.
- Response is a blob object: `{ "$type": "blob", "ref": {"$link": "..."}, "mimeType": "...", "size": N }`.
- Blob is in temporary storage until referenced by a record. Permanent then.

Stripping EXIF metadata is the **client's** responsibility. PDSes don't do it.

Don't link directly to a PDS's blob endpoint from a browser -- always proxy through a CDN with `Content-Security-Policy: default-src 'none'; sandbox`.

## Server expectations

If you're implementing an XRPC server:

- Return JSON error bodies for `/xrpc/*` paths even when proxies might not.
- Implement timeouts; clients will.
- Validate inputs against the Lexicon. The data model rules apply even without the Lexicon.
- HTTPS only on the open internet.
