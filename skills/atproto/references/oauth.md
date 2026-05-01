# OAuth

OAuth is the primary mechanism for clients to make authorized requests to PDSes. atproto's OAuth profile is more constrained than generic OAuth 2.0 -- a few things are mandatory rather than optional.

In practice you should use a library (`@atproto/oauth-client-node`, `@atproto/oauth-client-browser` in TS, `atproto/auth/oauth` in Go indigo). This file is what you need to know about the protocol regardless of library.

## Mandatory bits

- The `atproto` scope on every session. No exceptions.
- **PKCE** -- code challenge required for all clients.
- **PAR** (pushed authorization requests) -- the auth request goes via a backchannel, not the URL.
- **DPoP** with **server-issued nonces** -- every request signs a JWT that binds it to the client's key. The auth server provides nonces; you must use them.

If your library doesn't enforce all four, switch libraries.

## Client types

- **Confidential clients** -- have a backend that holds a signing key. Eligible for longer sessions.
- **Public clients** -- browser/mobile, no backend. Short-lived access tokens (15-30 min), single-use refresh tokens.

Both publish **client metadata JSON** at a public URL. The `client_id` *is* that URL. There is no central registration.

Example client metadata fields:

```json
{
  "client_id": "https://app.example.com/client-metadata.json",
  "client_name": "Example",
  "client_uri": "https://app.example.com",
  "redirect_uris": ["https://app.example.com/oauth/callback"],
  "scope": "atproto repo:com.example.status",
  "grant_types": ["authorization_code", "refresh_token"],
  "response_types": ["code"],
  "application_type": "web",
  "token_endpoint_auth_method": "none",
  "dpop_bound_access_tokens": true
}
```

Confidential clients add `jwks_uri` (or `jwks`) and use `private_key_jwt` for `token_endpoint_auth_method`.

## The dance

1. **User enters a handle or DID.** You resolve it to a DID and find the user's PDS from the DID document (`#atproto_pds` service).
2. **Discover the auth server.** Fetch `<pds>/.well-known/oauth-protected-resource`, then the auth server's `/.well-known/oauth-authorization-server`. (For Bluesky's PDSes, this currently lives at the entryway, not the PDS.)
3. **PAR request.** POST your auth params (including PKCE challenge, scope, login_hint) to the PAR endpoint; receive a `request_uri`.
4. **Redirect** the user to the authorization endpoint with `client_id` and `request_uri`.
5. **User authenticates** with their PDS / auth server.
6. **Callback** to your `redirect_uri` with `code`.
7. **Token exchange** at the token endpoint with PKCE verifier and DPoP proof. Receive access token, refresh token, and the granted scopes.
8. **Identity check.** Verify the user's `sub` (a DID) matches the DID you resolved in step 1. Otherwise a malicious auth server could authenticate you as anyone.

## Scopes

Beyond `atproto`, scopes are typed strings:

```
repo:<nsid-or-glob>             # write access to records in a collection
rpc?lxm=<nsid>&aud=<did>        # call a specific XRPC endpoint on a service
blob?accept=<mime-pattern>      # blob uploads
account                          # account-level operations
identity                         # DID/handle management
```

Examples:

- `repo:com.example.status` -- write the status collection.
- `rpc?lxm=*&aud=did:web:bsky.app%23bsky_appview` -- any RPC against the Bluesky app view.
- `blob?accept=image/*` -- upload images.

Transitional scopes for legacy compatibility:

- `transition:generic` -- approximates classic password-session powers.
- `transition:chat.bsky` -- chat access.
- `transition:email` -- email access.

The auth server returns the **granted** scopes in the token response. Always read those, don't assume you got what you requested.

## Token lifetime and refresh

- Access tokens: 15-30 minutes typical.
- Refresh tokens: single-use. Each refresh returns a new refresh token; the old one is dead.
- Sessions: reputation-dependent. Confidential clients get longer.

Treat tokens as opaque. Don't decode access tokens for client logic -- the structure isn't a stable API.

## DPoP nonces

Servers issue nonces in `DPoP-Nonce` response headers; clients must include the latest nonce in subsequent DPoP proofs. Stale-nonce errors come back as `use_dpop_nonce` -- retry with the new nonce.

## Critical "do not skip" steps

- Resolve the user's DID *first*, find their PDS, then OAuth against that PDS's auth server. Never trust an auth server's claim about who a user is without independent identity resolution.
- After token exchange, verify `sub` matches the DID you resolved.
- Bind the access token to a DPoP key you control.
- Honour DPoP nonces from the server.
