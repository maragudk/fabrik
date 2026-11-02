# Connecting Modal to your Datadog account

You can use the [Modal + Datadog Integration](https://docs.datadoghq.com/integrations/modal/)
to export Modal Function logs to Datadog. You'll find the Modal Datadog
Integration available for install in the Datadog marketplace.

## What this integration does

This integration allows you to:

1. Export Modal audit logs in Datadog
2. Export Modal Function logs to Datadog
3. Export container metrics to Datadog

## Installing the integration

Connecting this integration creates an API key in your Datadog account, which
requires Datadog org owner permissions. If you aren't an org owner, ask one to
complete the connection.

1. Open the [Modal Tile](https://app.datadoghq.com/integrations?integrationId=modal) (or the EU tile [here](https://app.datadoghq.eu/integrations?integrationId=modal))
   in the Datadog integrations page
2. Click "Install Integration"
3. Click Connect Accounts to begin authorization of this integration.
   You will be redirected to log into Modal, and once logged in, you’ll
   be redirected to the Datadog authorization page.
4. Click "Authorize" to complete the integration setup

## Metrics

The Modal Datadog Integration will forward the following metrics to Datadog:

* `modal.cpu.utilization`
* `modal.memory.usage`
* `modal.gpu.memory.usage`
* `modal.gpu.compute.utilization`
* `modal.gpu.power.usage`
* `modal.gpu.power.utilization`
* `modal.gpu.temperature`
* `modal.gpu.clock`
* `modal.gpu.count`
* `modal.container.running`
* `modal.container.terminations`
* `modal.input_events.elapsed_time_us`
* `modal.input_events.input_queue_time_us`
* `modal.input_events.coldstart_time_us`
* `modal.input_events.successes`
* `modal.input_events.total_inputs`
* `modal.function.pending_inputs`
* `modal.function.running_inputs`

All metrics are tagged with `container_id`, `environment_name`, `app_name`, `app_id`,
`function_name`, `function_id`, `workspace_name`, and `workspace_id`. Metrics from
GPU containers are additionally tagged with `gpu_billing_type`, the GPU type the
container is billed as (e.g. `H100`), which may differ from the physical GPU model
when a workload is scheduled onto a newer GPU.
`modal.container.terminations` is instead tagged with `container_id`,
`environment_name`, `app_name`, `app_id`, `workspace_name`, `workspace_id`,
`object_id`, `object_type`, and `reason`.

Deprecated metrics:

* `modal.memory.utilization` (use `modal.memory.usage`)
* `modal.gpu.memory.utilization` (use `modal.gpu.memory.usage`)

`modal.input_events.successes` and `modal.input_events.total_inputs` can be used
to measure the success rate of a certain function or app.

As an [official Datadog integration](https://docs.datadoghq.com/integrations/modal/),
Modal metrics are free on Datadog while logs are charged.

## Log attributes

Logs forwarded to Datadog include the following attributes:

* `container_id`
* `app_id`
* `app_name`
* `function_id`
* `function_name`
* `function_call_id`
* `input_id`
* `sandbox_id`
* `environment`
* `workspace`
* `workspace_id`

These are [log attributes](https://docs.datadoghq.com/logs/log_configuration/attributes_naming_convention/),
not tags. You can filter and search by them in Datadog's
[Log Explorer](https://docs.datadoghq.com/logs/explorer/) using the `@` prefix
(for example, `@container_id:<value>`).

## Structured logging

Logs from Modal are sent to Datadog in plaintext without any structured
parsing. This means that if you have custom log formats, you'll need to
set up a [log processing pipeline](https://docs.datadoghq.com/logs/log_configuration/pipelines/?tab=source)
in Datadog to parse them.

Modal passes log messages in the `.message` field of the log record. To
parse logs, you should operate over this field. Note that the Modal Integration
does set up some basic pipelines. In order for your pipelines to work, ensure
that your pipelines come before Modal's pipelines in your log settings.

## Cost Savings

The Modal Datadog Integration will forward all logs to Datadog which could be
costly for verbose apps. We recommend using either [Log Pipelines](https://docs.datadoghq.com/logs/log_configuration/pipelines/?tab=source)
or [Index Exclusion Filters](https://docs.datadoghq.com/logs/indexes/?tab=ui#exclusion-filters)
to filter logs before they are sent to Datadog.

All logs include the `environment` attribute. The simplest way to filter
logs is to create a pipeline that filters on this attribute and to isolate
verbose apps in a separate environment.

## Uninstalling the integration

Once the integration is uninstalled, all logs will stop being sent to
Datadog, and authorization will be revoked.

1. Navigate to the [Modal metrics settings page](http://modal.com/settings/metrics)
   and select "Delete Datadog Integration".
2. On the Configure tab in the Modal integration tile in Datadog,
   click Uninstall Integration.
3. Confirm that you want to uninstall the integration.
4. Ensure that all API keys associated with this integration have been
   disabled by searching for the integration name on the [API Keys](https://app.datadoghq.com/organization-settings/api-keys?filter=Modal)
   page.
