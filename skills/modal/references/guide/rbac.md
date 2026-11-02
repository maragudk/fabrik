# Role-Based Access Control (RBAC)

<Callout variant="gated-feature">
RBAC is available on the <a href="/pricing">Team and Enterprise plans</a>. Visit <a href="/settings/plans">Workspace settings</a> to upgrade.
</Callout>

Role-Based Access Control (RBAC) gives Workspace administrators more granular control over who can access and modify resources.

This is especially useful for protecting production while allowing broader access to development and staging.

Modal's RBAC system operates at two levels:

* **Workspace Roles** control overall Workspace permissions.
* **Environment Roles** control access to individual Environments.

## Workspace Roles

Modal [Workspaces](/docs/guide/workspaces) organize Modal Apps and other resources for a group of users. These roles control access at the level of the entire Workspace.

All Workspace Members have one of three Roles that determine their overall permissions:

* **Owner** — Full read-write access to everything in the Workspace, including billing, Workspace management, and all Environments. Can assign any Role to other members.
* **Manager** — Same as Owner, but cannot modify the Owner Role.
* **Member** — Can deploy and manage Apps, but cannot access billing, Workspace management, or other Workspace settings.

## Environment Roles

Modal [Environments](/docs/guide/environments) isolate Modal Apps and other resources from one another within a Workspace.

Every Environment has three Environment Roles that determine access to it:

* **Contributor** — Full read and write access to the Environment. Workspace Owners and Managers always have Contributor access.
* **Viewer** — Read-only access to resources in the Environment, including dashboards, logs, metrics, app and function configuration.
* **No Access** — No read or write access to the Environment.

Workspace Members default to **Contributor** in regular Environments. In a **Restricted** Environment, Members other than Workspace Owners and Managers use the Environment's default member Role, which can be **Contributor**, **Viewer**, or **No Access**. Workspace Owners and Managers always have **Contributor** access.

You can assign a **Contributor**, **Viewer**, or **No Access** Role to a Workspace Member in a Restricted Environment directly or through a [user group](/docs/guide/user-groups). Direct and group Roles take precedence over the default. If a Member has multiple direct or group Roles, the most permissive Role applies: **Contributor**, then **Viewer**, then **No Access**.

Service users do not use the member default: they default to **No Access** in every Environment and must be assigned a Role for each Environment they need.

## Setting up Restricted Environments

Create and manage Restricted Environments from [Environment settings](/settings/workspace-management/environments).

You can also create a Restricted Environment with [`modal environment create --restricted NAME`](/docs/cli/latest/environment#modal-environment-create).

Changing the default updates access only for Members who use it. Roles assigned directly to Members, group Roles, and service-user Roles are unchanged.

### Default access by actor

| Workspace Role               | Unrestricted Environment Default | Restricted with Contributor default | Restricted with Viewer default | Restricted with No Access default |
| ---------------------------- | -------------------------------- | ----------------------------------- | ------------------------------ | --------------------------------- |
| Workspace Owner              | Contributor                      | Contributor                         | Contributor                    | Contributor                       |
| Workspace Manager            | Contributor                      | Contributor                         | Contributor                    | Contributor                       |
| Workspace Member             | Contributor                      | Contributor                         | Viewer                         | No Access                         |
| Service user / service token | No Access                        | No Access                           | No Access                      | No Access                         |

Workspace Members can only be assigned an Environment Role in Restricted Environments. Service users can be given a Role on **any** Environment — Restricted or not — from their [tokens settings](/settings/tokens/service-users) or an Environment's Roles.

### No Access and Workspace defaults

Environments where a Member has **No Access** are omitted from Environment listings and selectors. Attempts to access the Environment directly are rejected.

A Restricted Environment with a **No Access** default can still be the Workspace's default Environment. Modal does not automatically choose another accessible Environment. Operations that use an inaccessible default fail, so the Member must explicitly select an Environment they can access.

## Service users and service tokens

[Service users](/docs/guide/service-users) are programmatic identities authenticated with API tokens. They are useful for CI/CD pipelines, deployment bots, and other machine-to-machine communication needs.

Unlike human users, service users do not have a Workspace-level role; their access is controlled entirely through Environment Roles.

| Use case                                     | Recommended identity                               | How access works                                                                                                                        |
| -------------------------------------------- | -------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------- |
| Interactive development or manual management | Human user                                         | Access is based on the user's Workspace Role, plus any Environment Role for restricted Environments                                     |
| Automation in CI/CD or deployment workflows  | Service user authenticated with a service token    | Access is based only on the service user's Environment Role                                                                             |
| Deploying to an Environment                  | Human user or service user with Contributor access | Deploying requires **Contributor** access to the target Environment; grant the service user that Role on each Environment it deploys to |

This makes service users the recommended way to let automation deploy to a specific Environment without granting broad Workspace permissions.

## Proxy Tokens

HTTP interfaces on [Endpoints](/docs/guide/endpoints), [Servers](/docs/guide/servers), and [Web Functions](/docs/guide/webhooks) can be protected with [Proxy Tokens](/docs/guide/webhook-proxy-auth), which authenticate inbound HTTP requests before they reach your containers.

On workspaces with RBAC enabled, Proxy Tokens are **scoped** — each token is explicitly associated with one or more Environments, and will only be accepted for endpoints deployed in those Environments. This prevents a token intended for a staging endpoint from being used to call a production one.

### Creating a scoped proxy token

1. Navigate to **Settings → Proxy Tokens** and click **New Token**.
2. Copy the token ID and secret — the secret is only shown once.
3. You will be prompted to select the Environments this token should be valid for.
4. Use the **Manage Environments** button on any existing scoped token to update its Environment associations. Changes take effect immediately, so removing an Environment will instantly revoke access for any clients using that token to call endpoints in that Environment.

Alternatively, you can create and manage Proxy Tokens via the [CLI](/docs/cli/latest/workspace#modal-workspace-proxy-tokens) or [Python SDK](/docs/sdk/py/latest/Workspace#proxy_tokens).

### Scoped vs. workspace-wide tokens

| Token type     | Who gets it                  | Valid for                                                  |
| -------------- | ---------------------------- | ---------------------------------------------------------- |
| Scoped         | Workspaces with RBAC enabled | Only the Environments explicitly associated with the token |
| Workspace-wide | Workspaces without RBAC      | Any Web Function in the workspace                          |

Existing workspace-wide tokens continue to work as-is. New tokens created on workspaces with RBAC enabled are scoped by default.

If RBAC is disabled on a workspace, scoped tokens fall back to workspace-wide access.

## Cross-Environment access

Restricted Environments prevent app and task identities in other Environments from accessing resources inside the restricted Environment. For more detail, see [Cross-Environment Lookups](/docs/guide/environments#cross-environment-lookups).

In practice, this means a task can access objects in its own Environment and other unrestricted Environments, but code running in another Environment cannot use APIs such as `modal.App.lookup()` or `Secret.from_name()` to reach into a restricted Environment.

This prevents privilege escalation from a less trusted Environment into a more sensitive one.

### Cross-Environment behavior for app and task identities

Access checks are evaluated against the **target** Environment. That means workloads running inside a restricted Environment can still access objects in an **unrestricted** Environment, but workloads running outside a restricted Environment cannot reach into it.

| Source Environment | Target Environment | Cross-Environment access |
| ------------------ | ------------------ | ------------------------ |
| Unrestricted       | Unrestricted       | Allowed                  |
| Unrestricted       | Restricted         | Denied                   |
| Restricted         | Unrestricted       | Allowed                  |
| Restricted         | Restricted         | Denied                   |

Same-Environment access is unaffected by these cross-Environment rules.

### Example: inbound vs. outbound access

Suppose you have two Environments:

* `prod` — restricted
* `test` — unrestricted

A task running in `test` cannot look up secrets, volumes, or Apps in `prod`.

A task running in `prod` can still access objects in `test`, because `test` is not restricted.

If both `prod` and `test` are restricted, then tasks in one cannot access objects in the other.

## Protecting production secrets with restricted Environments

A common RBAC setup is to place production secrets in a restricted production Environment and grant **Contributor** access only to the human users and service users that should be allowed to deploy or manage production.

| Scenario                                                                       | Result  |
| ------------------------------------------------------------------------------ | ------- |
| Developer in `dev` tries to edit a secret in restricted `prod`                 | Denied  |
| CI service user with Contributor access to restricted `prod` deploys to `prod` | Allowed |
| Task running in `prod` reads a secret in `prod`                                | Allowed |
| Task running in `prod` accesses objects in unrestricted `test`                 | Allowed |

This setup lets you keep development and testing more open while protecting production resources, including secrets, from accidental or unauthorized access.

## Common access patterns

| Pattern                                                                   | Allowed?                     | Notes                                                                                       |
| ------------------------------------------------------------------------- | ---------------------------- | ------------------------------------------------------------------------------------------- |
| Workspace Member views logs in a Restricted Environment                   | If Viewer or Contributor     | A Member whose effective Role is No Access cannot discover the Environment                  |
| Workspace Member deploys to a Restricted Environment                      | If Contributor               | Contributor access is required to deploy or modify resources                                |
| Workspace Owner or Manager deploys to a Restricted Environment            | Yes                          | Owners and Managers automatically have Contributor access                                   |
| Service user deploys to a Restricted Environment                          | Yes, if assigned Contributor | Service users have No Access by default and must be assigned Contributor to deploy          |
| Task running in `dev` reads a Secret in Restricted `prod`                 | No                           | Cross-Environment access into a Restricted Environment is denied                            |
| Task running in Restricted `prod` accesses objects in unrestricted `test` | Yes                          | Cross-Environment access is allowed when the target Environment is unrestricted             |
| User views dashboards or App details in a Restricted Environment          | If Viewer or Contributor     | Viewer access includes read-only views such as dashboards, logs, metrics, and configuration |
| Task accesses resources in its own Environment                            | Yes                          | Same-Environment access is unaffected by cross-Environment restrictions                     |
| Scoped proxy token used on a Web Function in an associated Environment    | Yes                          | Token must be explicitly associated with the target Environment                             |
| Scoped proxy token used on a Web Function in a non-associated Environment | No                           | Token is not valid for Environments it has not been associated with                         |

## FAQ

**Can I make Environments completely private?**

Yes. Set a Restricted Environment's default member Role to **No Access**, then assign **Viewer** or **Contributor** only to the Workspace Members and service users who need it. Other Members cannot discover the Environment. Workspace Owners and Managers always retain **Contributor** access.

**How do service tokens work with restricted Environments?**

Service tokens authenticate service users. Service users default to **No Access** on every Environment, restricted or not, and cannot read or write to an Environment until you assign them the **Viewer** or **Contributor** Role. This lets automated systems and CI/CD pipelines deploy and manage production without granting broad Workspace permissions.

**Can I use `modal.App.lookup()` across different restricted Environments?**

No. Apps cannot look up, read from, or write to objects in a different restricted Environment.

**Can code running in a restricted Environment access other Environments?**

Yes, but only when the target Environment is not restricted. A restricted Environment blocks access **into** it from other Environments.
