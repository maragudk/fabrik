# Audit Logs

<Callout variant="gated-feature">
Audit logs are available on the <a href="/pricing" target="_blank" rel="noopener">Enterprise plan</a>. Contact <a href="mailto:sales@modal.com">sales@modal.com</a> for more information.
</Callout>

Audit logs give your workspace an append-only record of the sensitive
actions that change its state — who did what, when, to which resource, and
from where. They are designed for compliance reviews, incident
investigation, and answering questions like *"did anyone delete this Secret
last Thursday?"* without asking Modal support.

Audit logs are viewable within the <a href="/settings/audit-logs" target="_blank" rel="noopener" class="text-accent hover:underline">settings page</a>.

<center>
<video controls autoplay muted playsinline>
<source src="https://modal-public-assets.s3.us-east-1.amazonaws.com/docs/audit-logs-v2-demo-2.mp4" type="video/mp4">
</video>
</center>

## Fields

Every audit event captures the same shape alongside the time it occurred:

| Field                 | What it is                                                                                                                         |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `action`              | The kind of change that happened — e.g. `secret.create`, `app.deploy`. See the full list [below](#actions).                        |
| `actor`               | The user or service user that initiated the action.                                                                                |
| `targets`             | The resource(s) the action affected, each recorded by ID so the event stays attributable after a rename or delete.                 |
| `context.environment` | The environment the action was scoped to.                                                                                          |
| `context.ip_address`  | The client IP address.                                                                                                             |
| `context.source`      | `web` for the dashboard, `sdk` for the Modal CLI and client libraries.                                                             |
| `status`              | Whether the action succeeded or failed.                                                                                            |
| `metadata`            | Action-specific extra fields — e.g. the old and new budget values for `workspace.set_budget`, or the requested region for a Proxy. |

## Filtering

Filters are entered in the search bar above the table as `key:value`
pairs, separated by spaces. Any filter can be **negated** by prefixing it
with `-` to exclude matching events. The search bar autocompletes keys
and values as you type.

For example:

| Filter                                       | Matches                                          |
| -------------------------------------------- | ------------------------------------------------ |
| `action:secret.create`                       | Every Secret created in the selected time range. |
| `-status:success`                            | All actions that did not succeed.                |
| `action:volume.delete` `-actor_type:service` | Volume deletions by non-service users.           |

## Actions

The table below lists every action currently recorded. New actions will be
added as additional workspace operations are instrumented.

> Note: **container runtime activity is not audited.** Audit logs record
> workspace-level actions (deploying an App, creating a Volume, revoking a
> token) — not individual Function invocations or Sandbox `exec` calls,
> which are captured in Function and Sandbox logs.

<br />

<!-- AUDIT_LOG_V2_ACTIONS_START: generated from ACTION_DESCRIPTIONS, do not edit by hand -->

| Action                                       | Description                                                                                                                                                                                                                                                         |
| -------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `access_grant.approve`                       | A workspace manager approved a pending Modal-admin access grant.                                                                                                                                                                                                    |
| `access_grant.revoke`                        | A workspace manager revoked an active Modal-admin access grant.                                                                                                                                                                                                     |
| `app.deploy`                                 | An App was deployed to the workspace (via `modal deploy` or implicitly via `App.lookup`).                                                                                                                                                                           |
| `app.expose_unauthenticated_url`             | An App's Function or Server was given an unauthenticated public URL. The function id and name are recorded in the event metadata.                                                                                                                                   |
| `app.promote`                                | An App was promoted from a staged version.                                                                                                                                                                                                                          |
| `app.rollback`                               | An App was rolled back to an earlier deployed version.                                                                                                                                                                                                              |
| `app.rollover`                               | An App was rolled over — its current version was redeployed, restarting running tasks.                                                                                                                                                                              |
| `app.run`                                    | An ephemeral App was started with `modal run` or `modal serve`.                                                                                                                                                                                                     |
| `app.stop`                                   | An App was stopped from the dashboard or with `modal app stop`.                                                                                                                                                                                                     |
| `container.stop`                             | A running container (task) was terminated from the dashboard or CLI. Routine container exits at the end of a call are not audited.                                                                                                                                  |
| `dict.create`                                | A Dict was created.                                                                                                                                                                                                                                                 |
| `dict.get`                                   | An existing Dict was looked up by name or by ID.                                                                                                                                                                                                                    |
| `domain.create`                              | A custom domain was attached to an environment.                                                                                                                                                                                                                     |
| `domain.delete`                              | A custom domain was removed.                                                                                                                                                                                                                                        |
| `endpoint.candidate_delete`                  | A candidate deployment was deleted from an Endpoint, and its backing App was stopped. The endpoint name and deployment ID are recorded in the event metadata.                                                                                                       |
| `endpoint.create_unauthenticated`            | An Endpoint was created without Modal Proxy Auth. The endpoint name is recorded in the event metadata.                                                                                                                                                              |
| `endpoint.stop`                              | An Endpoint was stopped, along with its backing Apps. The endpoint name is recorded in the event metadata.                                                                                                                                                          |
| `environment.create`                         | A new environment was created in the workspace.                                                                                                                                                                                                                     |
| `environment.delete`                         | An environment was deleted.                                                                                                                                                                                                                                         |
| `environment.get`                            | An environment was looked up by name.                                                                                                                                                                                                                               |
| `environment.set_budget`                     | An environment's spend budget was updated or cleared. The previous and new per-cycle budget values, effective maximum budget, and whether the budget changed are recorded in event metadata.                                                                        |
| `environment.set_default_member_role`        | An environment's default member role was updated. It applies to workspace members without an explicit environment role; the previous and new defaults are recorded in event metadata.                                                                               |
| `environment.set_managed`                    | An environment was toggled between managed and unmanaged. Disabling managed access removes every per-environment role for that environment; whether it's now managed is recorded in the event metadata.                                                             |
| `environment.update`                         | An environment's settings changed — name, web suffix, per-environment concurrency limits, or whether unauthenticated resources are blocked. Before/after values are recorded in the event metadata.                                                                 |
| `environment.update_group`                   | A user group's per-environment role (Contributor / Viewer / No Access) was changed, or the group's environment-level access was removed.                                                                                                                            |
| `environment.update_member`                  | A user or service user's per-environment role (Contributor / Viewer / No Access) was changed, or their environment-level access was removed. Independent of their workspace-level role.                                                                             |
| `image.delete`                               | An Image was deleted.                                                                                                                                                                                                                                               |
| `integration.set_telemetry_signals`          | The telemetry signals forwarded to a customer integration were changed.                                                                                                                                                                                             |
| `invite.create_for_workspace`                | A workspace-wide invite link was generated by a workspace admin.                                                                                                                                                                                                    |
| `member.delete`                              | A member was removed from the workspace.                                                                                                                                                                                                                            |
| `member.set_role`                            | A workspace member's workspace-wide role (Owner / Manager / User) was changed. The affected member(s) appear in the event targets and the new role(s) are recorded in the event metadata. Per-environment access is set separately via `environment.update_member`. |
| `nfs.create`                                 | A NetworkFileSystem was created.                                                                                                                                                                                                                                    |
| `nfs.get`                                    | An existing NetworkFileSystem was looked up by name.                                                                                                                                                                                                                |
| `oauth_grant.approve`                        | A user authorized a third-party OAuth client to act on the workspace with their access. The client and the granted scopes are recorded in the event metadata.                                                                                                       |
| `oauth_grant.revoke`                         | An OAuth authorization was revoked, ending the client's access on behalf of that user.                                                                                                                                                                              |
| `proxy.add_ip`                               | A static egress IP was added to a Proxy.                                                                                                                                                                                                                            |
| `proxy.create`                               | A Proxy was created. The requested name and region are recorded in the event metadata.                                                                                                                                                                              |
| `proxy.delete`                               | A Proxy was deleted.                                                                                                                                                                                                                                                |
| `proxy_token.add_environment`                | An environment was added to a Proxy Auth token's allowed environments. The environment name is recorded in the event metadata.                                                                                                                                      |
| `proxy_token.create`                         | A Proxy Auth token was created. Whether the token is scoped to specific environments is recorded in the event metadata.                                                                                                                                             |
| `proxy_token.delete`                         | A Proxy Auth token was deleted.                                                                                                                                                                                                                                     |
| `proxy_token.remove_environment`             | An environment was removed from a Proxy Auth token's allowed environments.                                                                                                                                                                                          |
| `proxy_token.update`                         | A Proxy Auth token was updated. Previous and new field values are recorded in the event metadata.                                                                                                                                                                   |
| `queue.delete`                               | A Queue was deleted.                                                                                                                                                                                                                                                |
| `queue.get`                                  | An existing Queue was looked up by ID.                                                                                                                                                                                                                              |
| `sandbox.create`                             | A Sandbox was launched.                                                                                                                                                                                                                                             |
| `sandbox.terminate`                          | A Sandbox was explicitly terminated before its natural exit.                                                                                                                                                                                                        |
| `secret.create`                              | A Secret was created or its values were overwritten (via `modal secret create` or the dashboard).                                                                                                                                                                   |
| `secret.delete`                              | A Secret was deleted.                                                                                                                                                                                                                                               |
| `secret.get`                                 | A named Secret was resolved to an ID (e.g. at deploy, or when opening a secret in the dashboard). Values are not returned; only the Secret's ID and metadata are.                                                                                                   |
| `secret.update`                              | Individual keys of an existing Secret were added, changed, or removed (via the dashboard). The added, updated, and removed key names are recorded in the event metadata; values are never recorded.                                                                 |
| `service_user.create`                        | A service user was created together with its API token. The service user's name and the id of the token issued to it are recorded in the event metadata.                                                                                                            |
| `service_user.delete`                        | A service user was deleted, revoking its API token and every environment role granted to it. The revoked token's id is recorded in the event metadata.                                                                                                              |
| `token.create`                               | An API token was created. The token's name and expiration are recorded in the event metadata.                                                                                                                                                                       |
| `token.delete`                               | An API token was revoked.                                                                                                                                                                                                                                           |
| `user.create`                                | A new user account was created.                                                                                                                                                                                                                                     |
| `user_group.create`                          | A user group was created in the workspace.                                                                                                                                                                                                                          |
| `user_group.delete`                          | A user group was deleted from the workspace.                                                                                                                                                                                                                        |
| `user_group.update`                          | A user group's name, membership, or environment roles were updated.                                                                                                                                                                                                 |
| `volume.create`                              | A Volume was created.                                                                                                                                                                                                                                               |
| `volume.delete`                              | A Volume was deleted.                                                                                                                                                                                                                                               |
| `volume.get`                                 | An existing Volume was looked up by name or by ID.                                                                                                                                                                                                                  |
| `volume.rename`                              | A Volume was renamed.                                                                                                                                                                                                                                               |
| `workspace.create`                           | A new workspace was created.                                                                                                                                                                                                                                        |
| `workspace.downgrade`                        | A workspace was downgraded to a lower billing plan.                                                                                                                                                                                                                 |
| `workspace.join`                             | A user joined a workspace (by accepting an invite or self-serve signup).                                                                                                                                                                                            |
| `workspace.leave`                            | A user left a workspace.                                                                                                                                                                                                                                            |
| `workspace.rename`                           | A workspace was renamed. The previous and new workspace names are recorded in the event metadata. Renaming changes the workspace's dashboard URLs. Deployed web endpoints keep their existing URLs until they are redeployed.                                       |
| `workspace.set_budget`                       | A workspace's spend budget was updated. The previous and new per-cycle budget values are recorded in the event metadata.                                                                                                                                            |
| `workspace.set_default_environment_settings` | A workspace's default environment settings were updated. Environments without an explicit override inherit these defaults. Before/after values for blocked unauthenticated resources are recorded in the event metadata.                                            |
| `workspace.set_max_member_token_lifetime`    | A workspace's maximum member API token lifetime was updated. Before/after values in seconds are recorded in the event metadata; an unset value means no cap.                                                                                                        |
| `workspace.set_net_spend_limit`              | A workspace's out-of-pocket (net) spend limit was updated. The previous and new per-cycle limits are recorded in the event metadata.                                                                                                                                |
| `workspace.update_github_autojoin`           | Whether members of the linked GitHub organization can join the workspace without an invite was changed.                                                                                                                                                             |
| `workspace.update_idp`                       | A workspace's SAML identity provider configuration was changed. Enabling SSO enforcement immediately logs out sessions not authenticated through SAML.                                                                                                              |
| `workspace.upload_idp_metadata`              | A SAML metadata document was uploaded for a workspace, replacing any file Modal already hosted for it. This sets the workspace's SSO metadata URL and the identity provider whose sign-ins Modal will accept.                                                       |

<!-- AUDIT_LOG_V2_ACTIONS_END -->
