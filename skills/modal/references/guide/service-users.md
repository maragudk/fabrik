# Service Users

<Callout variant="gated-feature">
Service users are available on the <a href="/pricing">Team and Enterprise plans</a>. Visit <a href="/settings/plans">Workspace settings</a> to upgrade.
</Callout>

Service users are programmatic accounts that allow automated systems to interact with Modal. They're ideal for CI/CD pipelines, automated deployments, and other workflows that need to authenticate.

For enhanced security, by default a Service User has no access to any of the Environments in the Workspace. Note that this differs from Workspace Members, who default to **Contributor** in all Environments.

All Service Users must be explicitly granted access to any Environments that they interact with. A Service User may hold either a **Viewer** or a **Contributor** role in a given Environment, though this may change as Modal's authentication model evolves. See [Role-Based Access Control](/docs/guide/rbac) for a more in depth discussion of these Roles.

## Create a Service User

### Using the Dashboard

Service users are only available for shared workspaces. You will need workspace owner or manager privileges to create service users.

To create a service user in the Dashboard:

1. Go to your workspace [tokens settings page](/settings/tokens/service-users)
2. Click **New Service User**
3. Enter a name for your service user (must be lowercase alphanumeric, can contain hyphens or underscores)
4. Click **Create**
5. Copy the `MODAL_TOKEN_ID` and `MODAL_TOKEN_SECRET`. **This is the only time you can view the token secret** for security reasons.
6. Click **Configure environments** to grant the service user access to specific Environments.

### Using the Command Line

Alternatively, you can create a new Service User on the command line:

```sh
modal workspace service-users create test-service-user-cli
```

As before, the name of the Service User must consist of lowercase alphanumeric, `-`, and `_` characters. You can optionally provide an expiration time (in seconds) by passing a value with the `--expires-in` option. See the [reference docs](https://modal.com/docs/cli/latest/workspace#modal-workspace-service-users-create) for more information.

Running this command will print the `MODAL_TOKEN_ID` and `MODAL_TOKEN_SECRET` values for the new Service User to standard output. Again, this is the only time you can view the token secret for security reasons.

To grant the new Service User access to Environments, use the [`set-role` subcommand](https://modal.com/docs/cli/latest/workspace#modal-workspace-service-users-set-role):

```sh
modal workspace service-users set-role test-service-user-cli dev contributor
```

Valid roles include `viewer` and `contributor`. Additionally, you may pass `no-access` to revoke access to a specific Environment.

### Creating Service Users from Python Directly

Finally, you can also create a new Service User directly from Python:

```python notest
ws = modal.Workspace.from_context()
token_data = ws.service_users.create("test-service-user-sdk", expires_in=None)
```

You can then grant the new service user a role:

```python notest
ws.service_users.set_role("test-service-user-sdk", "prod", role="viewer")
```

Again, `role` may be either `"viewer"`, `"contributor"`, or `"no-access"`.

## Use Service User Tokens

Set the service user credentials as environment variables in your automated environment:

```bash
export MODAL_TOKEN_ID=your-token-id
export MODAL_TOKEN_SECRET=your-token-secret
```

Once configured, you can use Modal's CLI and Python SDK as usual:

```bash
modal deploy your_app.py
```

## Delete a Service User

Deleting a Service User will immediately revoke the credentials associated with that Service User. This means that any program that uses those credentials will no longer be able to authenticate with Modal. Deletion is irreversible.

To remove a service user in the Dashboard:

1. Go to the [tokens settings page](/settings/tokens/service-users)
2. Find the service user in the table
3. Click **Delete** when you hover over the row

You can also do this in the command line:

```sh
modal workspace service-users delete test-service-user-cli
```

or from Python directly.

```python notest
ws.service_users.delete("test-service-user-sdk")
```

## Securing Service Users

Because service user tokens are long-lived and used in automated environments, it's important to limit their access to only what's necessary:

* **Store tokens securely.** Use a secrets manager or your CI/CD platform's built-in secrets storage rather than hardcoding tokens in source code or configuration files.
* **Grant least-privilege access.** Because service users start with **No Access**, assign the **Viewer** or **Contributor** role only on the Environments they actually need, keeping production isolated from development and staging.
