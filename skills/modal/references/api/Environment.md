# Environment


```python
class Environment(modal.object.Object)
```


## hydrate

```python
hydrate(self, client=None)
```
Synchronize the local object with its identity on the Modal server.

It is rarely necessary to call this method explicitly, as most operations
will lazily hydrate when needed. The main use case is when you need to
access object metadata, such as its ID.

*Added in v0.72.39*: This method replaces the deprecated `.resolve()` method.

## name

```python
name(self)
```


## objects


```python
objects: EnvironmentManager
```

Namespace with methods for managing Environment objects.


### objects.create

```python
create(self, name, *, restricted=False, default_role=None,
    experimental_options=None, client=None)
```
Create a new Environment.

**Examples:**

```python notest
modal.Environment.objects.create("my-environment")
```

### objects.list

```python
list(self, *, client=None)
```
Return a list of hydrated Environment objects.

**Examples:**

```python notest
environments = modal.Environment.objects.list()
print([e.name for e in environments])
```

### objects.delete

```python
delete(self, name, *, client=None)
```
Delete a named Environment.

Warning: This is irreversible and will transitively delete all objects in the Environment.

**Examples:**

```python notest
modal.Environment.objects.delete("my-environment")
```

## roles


```python
roles: EnvironmentRolesManager
```

Namespace with methods for managing the Environment Roles of users and service users.

See https://modal.com/docs/guide/rbac for more information on Environment Roles.


### roles.list

```python
list(self, *, exclude_default=False)
```
Enumerate the Environment Role for each user and service user in the workspace.

**Examples:**

```python notest
roles = modal.Environment.from_name("my-env").roles.list()
print(roles)
# {
#     "users": {"alice": "contributor", "bob": "viewer", "carol": "contributor"},
#     "service_users": {"alice-bot": "contributor", "ops-bot": "viewer", "ci-bot": "no-access"},
# }
```

**Parameters**

<Parameter name="exclude_default" type="bool" defaultValue="False" description="If `True`, only include roles that are directly assigned." />

### roles.update

```python
update(self, *, users=None, service_users=None)
```
Update the Environment Role of users and service users.

Each role is one of 'contributor', 'viewer', or 'no-access'. Service users can be
assigned a role on any Environment, while workspace members can only be assigned a
role on restricted Environments.

**Examples:**

```python notest
env = modal.Environment.from_name("my-restricted-env")
env.roles.update(
    users={"alice": "contributor", "bob": "viewer"},
    service_users={"alice-bot": "contributor"},
)
```

## from_context

```python
from_context(*, client=None)
```
Look up an Environment object using the current context.

This method returns the Environment that is defined by the local configuration
(i.e., your active profile or the `MODAL_ENVIRONMENT` environment variable), or
it fetches the default environment from the server when not defined locally.
If called inside a Modal container, it will return the Environment that container
is associated with.

## from_name

```python
from_name(name, *, create_if_missing=False, client=None)
```
Look up an Environment object using its name.

## billing


```python
billing: EnvironmentBillingManager
```

Namespace for Environment billing APIs.

```python
__init__(self, environment)
```
mdmd:ignore

### billing.report

```python
report(self, *, start, end=None, resolution="d", tag_names=None)
```
Return a cost report for Environment usage, broken down by object and time.

**Parameters**

<Parameter name="start" type="datetime" description="Start of the report, inclusive and rounded to the beginning of the interval. Must be in UTC or timezone-naive (interpreted as UTC)." />
<Parameter name="end" type="datetime | None" defaultValue="None" description="End of the report, exclusive. Must be in UTC or timezone-naive. Partial final intervals will be excluded from the report." />
<Parameter name="resolution" type="str" defaultValue="&quot;d&quot;" description="Resolution, e.g. &quot;d&quot; for daily or &quot;h&quot; for hourly." />
<Parameter name="tag_names" type="list[str] | None" defaultValue="None" description="List of tag names; each row will include the tag name and value in use for that object during the relevant time interval. Pass `[&quot;*&quot;]` to include all tags in the report." />

**Returns**

A list of `BillingReportItem` dataclasses. Each item reports the cost attributed to
a specific Modal object during a given time interval. Cost is further broken down by
the resource type that generated it (e.g. CPU, Memory, specific GPU usage).
Note that the specific resource types included in the breakdown are subject to change
as Modal's billing model evolves.

**See Also**

- [`modal environment billing report`](https://modal.com/docs/cli/latest/environment#modal-environment-billing-report):
  An environment report CLI that has convenience features around relative time range queries
  and JSON/CSV output.
- [`Workspace.billing.report()`](https://modal.com/docs/sdk/py/latest/Workspace#billingreport):
  An analogous report API for the entire Workspace.

### billing.summary

```python
summary(self, cycle=None)
```
Return a summary of environment cost over a single billing cycle determined by `cycle`.

Unlike the analogous `Workspace.billing.summary()`, this API only emits metered cost
information. This is because billing adjustments due to credits, free storage, etc. are
applied at the Workspace level, and thus cannot be attributed to individual Environments.

**Parameters**

<Parameter name="cycle" type="str | datetime | None" defaultValue="None" description="Start of the summary, inclusive. Must be the first of a month, and must be in UTC or timezone-naive (interpreted as UTC). If provided as a string, it must either be formatted as an ISO 8601 month (YYYY-MM), or must be one of the convenience spellings &quot;this month&quot; or &quot;last month&quot;. If not provided, `cycle` defaults to the first of the current month (in which case a summary is generated for the current billing cycle)." />

**Returns**

A single `EnvironmentBillingSummary` dataclass containing the following fields:
- `metered_cost` representing cost before any adjustments, and
- `metered_cost_breakdown` containing a breakdown of that cost by the Modal resources
  that generated it. The exact keys of this are subject to change as Modal's billing
  model evolves.

All values are reported as `decimal.Decimal`s.

**See Also**

- [`modal environment billing summary`](https://modal.com/docs/cli/latest/billing#modal-environment-billing-summary):
  An environment summary CLI that has convenience features around relative time range queries.
- [`Environment.billing.report()`](https://modal.com/docs/sdk/py/latest/Environment#billingreport):
  An analogous report API that is scoped to a specific Environment.
