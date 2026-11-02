# Connecting Modal to your OpenTelemetry Provider

You can export Modal logs to your [OpenTelemetry](https://opentelemetry.io/docs/what-is-opentelemetry/)
provider using the Modal OpenTelemetry integration. This integration is compatible with
any observability provider that supports the OpenTelemetry HTTP APIs.

## What this integration does

This integration allows you to:

1. Export Modal audit logs to your provider
2. Export Modal Function logs to your provider
3. Export container metrics to your provider

## Metrics

The Modal OpenTelemetry Integration will forward the following metrics to your provider:

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

Deprecated metrics:

* `modal.memory.utilization` (use `modal.memory.usage`)
* `modal.gpu.memory.utilization` (use `modal.gpu.memory.usage`)

`modal.input_events.successes` and `modal.input_events.total_inputs` can be used to measure the success rate of a certain function or app.

These metrics are tagged with `container_id`, `environment_name`, `app_name`,
`app_id`, `function_name`, `function_id`, `workspace_name`, and `workspace_id`.
Metrics from GPU containers are additionally tagged with `gpu_billing_type`, the GPU
type the container is billed as (e.g. `H100`), which may differ from the physical GPU
model when a workload is scheduled onto a newer GPU.
`modal.container.terminations` is instead tagged with `container_id`,
`environment_name`, `app_name`, `app_id`, `workspace_name`, `workspace_id`,
`object_id`, `object_type`, and `reason`.

## Custom metrics

<Callout variant="beta">

Contact us to enable custom metrics for your workspace.

</Callout>

The Modal OpenTelemetry Integration allows you to send custom metrics and spans to your provider. You will
then need to export our collector environment variables. These configure the OpenTelemetry SDK
to send messages to our collector in HTTP format. You don't need to do this to get the
out-of-the-box metrics above, only for your own custom metrics.

```python
@app.function(
   secrets=[modal.Secret.from_dict({
      "OTEL_EXPORTER_OTLP_ENDPOINT": "otlp-collector.modal.local:4317",
      "OTEL_EXPORTER_OTLP_INSECURE": "true",
      "OTEL_EXPORTER_OTLP_PROTOCOL": "http/protobuf",
   })],
)
def custom_metrics():
   ...
```

All OpenTelemetry SDKs should pick this configuration up, and your custom metrics and spans will be
sent to your configured provider.

## Installing the integration

1. Find out the endpoint URL for your OpenTelemetry provider. This is the URL that
   the Modal integration will send logs to. Note that this should be the base URL
   of the OpenTelemetry provider, and not a specific endpoint. For example, for the
   [US New Relic instance](https://docs.newrelic.com/docs/opentelemetry/best-practices/opentelemetry-otlp/#configure-endpoint-port-protocol),
   the endpoint URL is `https://otlp.nr-data.net`, not `https://otlp.nr-data.net/v1/logs`.
2. Find out the API key or other authentication method required to send logs to your
   OpenTelemetry provider. This is the key that the Modal integration will use to authenticate
   with your provider. Modal can provide any key/value HTTP header pairs. For example, for
   [New Relic](https://docs.newrelic.com/docs/opentelemetry/best-practices/opentelemetry-otlp/#api-key),
   the header is `api-key`.
3. Create a new OpenTelemetry Secret in Modal with one key per header. These keys should be
   prefixed with `OTEL_HEADER_`, followed by the name of the header. The value of this
   key should be the value of the header. For example, for New Relic, an example Secret
   might look like `OTEL_HEADER_api-key: YOUR_API_KEY`. If you use the OpenTelemetry Secret
   template, this will be pre-filled for you.
4. Navigate to the [Modal metrics settings page](http://modal.com/settings/metrics) and configure
   the OpenTelemetry push URL from step 1 and the Secret from step 3.
5. Save your changes and use the test button to confirm that logs are being sent to your provider.
   If it's all working, you should see a `Hello from Modal! 🚀` log from the `modal.test_logs` service.

## Uninstalling the integration

Once the integration is uninstalled, all logs will stop being sent to
your provider.

1. Navigate to the [Modal metrics settings page](http://modal.com/settings/metrics)
   and disable the OpenTelemetry integration.
