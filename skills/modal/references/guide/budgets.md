# Budgets

Modal budgets let you cap usage at both the Workspace and Environment level:

* **Workspace budget**: a monthly cap for total Workspace usage across the
  Workspace.
* **Environment budget**: a monthly cap for compute usage in a specific
  Environment.

Only Workspace **Owners** and **Managers** can set, edit, or remove budgets. See [Workspace roles](/docs/guide/workspaces#administering-workspace-membership) for role details.

## When to use each budget

* Use a **Workspace budget** when you want one overall monthly cap for the Workspace.
* Add **Environment budgets** when multiple teams or workloads share a Workspace and need independent usage guardrails.
* Keep both enabled when you want per-Environment isolation without losing a Workspace-wide hard cap.

## How limits apply

Workspace and Environment budgets are enforced together:

* The Workspace budget is the hard outer cap for the entire Workspace.
* If an Environment has no explicit budget, it inherits the Workspace effective limit.
* You cannot set an Environment budget to a value that exceeds the Workspace effective cap.
* Environment budgets do not need to sum to the Workspace budget.

Example: if your Workspace budget is `$50`, setting Environment budgets of `$30` and `$40` does not raise the Workspace cap. The Workspace can still hit `$50` first, without hitting either Environment budget.

## Workspace budgets

Workspace budgets (also shown as your **usage limit** in the dashboard) cap
total **usage** for the Workspace during the current billing cycle — before
credits are applied.

You can set, edit, or remove a Workspace budget on the [Usage & Billing](/settings/usage) page.

The maximum budget you can set depends on prior successful charges for the Workspace. If incremental usage charges succeed, that maximum can increase.

## Spend limits

A Workspace **spend limit** is a monthly cap on net charges (what you pay out
of pocket after credits are applied). This is separate from your Workspace
budget, which caps usage.

When the spend limit is reached, Modal stops workloads that would incur
additional out-of-pocket charges. Workloads that can still be covered by
remaining applicable credits may continue until the usage limit is reached.

If you do not set a custom spend limit, Modal uses the cycle's usage limit
minus credits. For example, if your usage limit is `$100` and you have `$30`
in credits, the default spend limit is `$70`.

Workspace Owners and Managers can set, edit, or reset the spend limit
on the [Usage & Billing](/settings/usage) page. Use **Reset to default** to
clear a custom value and return to the cycle's usage limit minus credits.

## Environment budgets

<Callout variant="gated-feature">
  Environment budgets are available on the <a href="/pricing"
    >Team and Enterprise plans</a
  >. Visit <a href="/settings/plans">workspace settings</a> to upgrade.
</Callout>

Environment budgets cap **compute usage** for a single Environment within the same billing cycle. Note that this means it does not include all Workspace-level charges (for example, storage, reservations, and network egress), so Environment budget usage is not a full invoice total by itself.

You can set, edit, or remove Environment budgets on the [Workspace Management → Environments](/settings/workspace-management/environments) page.
