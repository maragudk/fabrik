# Region selection

Modal runs containers globally across multiple different clouds. By default, all inputs to Modal Functions are routed through our servers in Virginia, USA (`us-east`) before being sent to a container for execution.

You can observe the location identifier of a container [via an environment variable](/docs/guide/environment_variables). Logging this environment variable alongside latency information can reveal when geography is impacting your application performance.

## Specifying a container region

To run your Modal Function containers in a specific region, pass a `region=` argument to the `function` decorator:

```python
@app.function(region=["us-west"])
def f():
    ...
```

Sandboxes accept the same `region=` argument on `Sandbox.create`:

```python notest
sb = modal.Sandbox.create(region=["us-west"], app=app)
```

This can be particularly useful when running a latency-sensitive app that needs to run near an external DB.

### Pricing

A multiplier on top of our [base usage pricing](/pricing) will be applied to any Function or Sandbox that has a container region defined.

| **Region type**         | **Multiplier** |
| ----------------------- | -------------- |
| Broad (e.g. `us`)       | 1.15x          |
| Narrow (e.g. `us-west`) | 1.75x          |

Here's an example: let's say you have a Function or Sandbox container that uses 1 T4, 1 CPU core, and 1GB memory. You've specified that it should run in `us-west`. The cost to run it for 1 hour would be `((T4 hourly cost) + (CPU hourly cost for one core) + (Memory hourly cost for one GB)) * 1.75`.

If you specify multiple container regions and they span the two categories above, we will apply the smaller of the two multipliers.

### Container region options

Modal offers different levels of granularity for container regions. Use broader regions when possible, as this increases the pool of available resources your Function or Sandbox containers can be assigned to, which improves cold-start time and availability.

```
  Broad          Narrow               Notes
 ===========================================================
  "us"                                United States
                 "us-east"
                 "us-central"
                 "us-south"
                 "us-west"
------------------------------------------------------------
  "eu"                                European Economic Area
                 "eu-west"
                 "eu-north"
                 "eu-south"
------------------------------------------------------------
  "ap"                                Asia-Pacific
                 "ap-northeast"
                 "ap-southeast"
                 "ap-south"
                 "ap-melbourne"
                 "jp"                 Japan
                 "au"                 Australia
------------------------------------------------------------
                 "uk"                 United Kingdom
------------------------------------------------------------
                 "ca"                 Canada
------------------------------------------------------------
                 "me"                 Middle East
------------------------------------------------------------
                 "sa"                 South America
------------------------------------------------------------
                 "af"                 Africa
------------------------------------------------------------
                 "mx"                 Mexico
```

Need access to more granular region definitions? Contact <sales@modal.com>.

## Regional routing

In addition to letting you specify the region a Function's containers run in, Modal also allows you to specify which region your inputs and outputs will be routed through to reduce network overhead. By default, this is `us-east` (Virginia, USA).

This doesn't apply to Sandboxes, as most operations go directly to the container (with some minor exceptions that are routed through `us-east`).

### Specifying a routing region

To have your Modal Function's traffic route through a specific region, pass a `routing_region=` argument to the `function` decorator.

```python
@app.function(routing_region="us-west")
def f():
    ...
```

The valid options for `routing_region=` are:

* `us-east` (Virginia, USA)
* `us-west` (Oregon, USA)
* `eu-west` (Dublin, Ireland)
* `ap-south` (Mumbai, India)

### Current restrictions

`routing_region=` can only be set during the initial deployment of a Function and cannot be changed in a subsequent redeployment. To change the routing region, a new Function should be created. Functions specifying a routing region outside of `us-east` can only be invoked with `.remote()` or `.map()` or via HTTP for [Web Functions](/docs/guide/webhooks).

[Inputs and outputs larger than 2 MiB](/docs/guide/security#data-retention) are still uploaded to object storage in `us-east`.

## Optimizing latency

Modal has a variety of tools to optimize network latency--even down to ~10ms in extreme cases like real-time robotics. Using container region selection in conjunction with a nearby routing region can eliminate significant network overhead.

[Cloudping.co](https://www.cloudping.co) provides good estimates of the latency between regions. For example, the round-trip latency between AWS `us-east` (Virginia, USA) and `us-west` (Oregon, USA) is around 60ms.

Splitting out regional deployments with separate Functions can be done like so:

```python
def f():
    ...

@app.function(region=["us-central", "us-west"], routing_region="us-west")
def f_us_west():
    return f()

@app.function(region="ap", routing_region="ap-south")
def f_ap_south():
    return f()
```

To optimize latency further, please contact us on [Slack](https://modal.com/slack) or at <support@modal.com>.
