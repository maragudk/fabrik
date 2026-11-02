# High-performance LLM inference

This high-level guide documents the key techniques used to achieve high performance
when running LLM inference on Modal.

Open weights models and open source inference engines have
closed much of the gap with proprietary models and proprietary engines
and continue to improve as they attract work from a broad community.
It is now and will increasingly be economical to run many generative AI applications in-house,
rather than relying on external providers.

Achieving competitive performance and cost is not instantaneous, however.
It requires some thought and tuning.
And LLM inference is in many ways quite different to the web serving and database workloads
that engineers are used to deploying and optimizing.

This guide collects techniques we have seen work in production inference deployments.
We include code samples so that you can try high-performance LLM inference for yourself.

We split the guide by the key performance criterion that matters for the workload:

* **[throughput](#achieving-high-throughput-llm-inference-tps)**,
  for large "jobs" made of many parallel requests that are only finished when they all finish,
* **[latency](#minimizing-llm-inference-latency-ttfttpotttlt)**,
  for serving each individual request as fast as possible, usually on human-interactive timescales,
* **[cold start time](#high-performance-llm-inference-for-bursty-workloads-cold-start-time)**,
  for bursty workloads that mix latency- and throughput-sensitive components.

This high-level guide and the attendant code samples are intended to kick-start
your own process of inference deployment and performance optimization.
You can find [baseline benchmarks](/llm-almanac/advisor)
and [benchmarking recommendations](/llm-almanac/how-to-benchmark)
in our [LLM Engineer's Almanac](/llm-almanac/workloads).

If you just want to get started running a basic LLM server on Modal, see
[this example](https://modal.com/docs/examples/llm_inference).
If you just want to dive into code, see
[this example for high throughput](https://modal.com/docs/examples/vllm_throughput),
[this example for low latency](https://modal.com/docs/examples/sglang_low_latency),
and [this example for low cold start time](https://modal.com/docs/examples/sglang_snapshot).

## Achieving high throughput LLM inference (TPS)

The quintessential "high throughput" LLM inference workload is a database backfill:
on a trigger, a large number (100s or more) of rows need to be processed,
e.g. to produce a sentiment score as part of an analytics pipeline
or to produce a generation that will be scored as part of offline evals.
No person or system is waiting on the result from any particular row.

Performance is defined by *throughput*, the rate at which tasks are completed,
which translates to end-to-end latency for the entire job.
For most deployments, this in turn directly determines cost.
It is measured in tokens per second (TPS).

Many, but not all, high throughput LLM inference applications have large contexts and small outputs,
which means they are dominated by prefill/prompt processing time, rather than decode/token generation time.
Combined with batching that increases
[arithmetic intensity](https://modal.com/gpu-glossary/perf/arithmetic-intensity),
throughput-oriented LLM inference jobs are generally
[compute-bound](https://modal.com/gpu-glossary/perf/compute-bound).

In general, high throughput is easier to achieve than low latency.
GPUs are inherently [designed for maximum throughput](https://modal.com/gpu-glossary/perf/latency-hiding).
Additionally, LLM training is a throughput-sensitive workload, so good kernels
are typically made available open source earlier.

For instance, the [Flash Attention 4 kernel](/blog/reverse-engineer-flash-attention-4)
that extends the Flash Attention kernel series to [Blackwell GPUs](https://modal.com/blog/introducing-b200-h200)
is, at time of writing months after its initial release,
primarily suitable for throughput-sensitive applications -- but watch this space!

For related reasons, we don't recommend using 4bit floating point (FP4) for these jobs.
FP4 is only supported in [Blackwell or later GPUs](https://modal.com/gpu-glossary/device-software/compute-capability).
Instead, we recommend the more mature 8bit floating point (FP8),
supported in Hopper or later GPUs (one generation back).

On Modal, the [rates](/pricing) for 16bit FLOP/$ are roughly the same across
A100s, H100s, and B200s -- newer GPUs run faster but cost more to match.
So peak throughput per *dollar* per replica is roughly the same,
even though throughput per *second* per replica is lower.

But older GPUs running at lower rates offer a few advantages:

* any time spent [underutilizing the GPUs](/blog/gpu-utilization-guide) is less expensive
* GPUs a generation or two back are generally available in larger quantities from hyperscalers

Throughput-oriented jobs don't necessarily benefit from scaling up each replica to more GPUs.
The aggregate throughput is the same as more replicas with fewer GPUs,
but fewer GPUs means reduced communication overhead and
reduced complexity, especially for single GPU-per-replica deployments.
Importantly, you must be able to fit a large enough batch of sequences
into the [GPU RAM](https://modal.com/gpu-glossary/device-hardware/gpu-ram)
that you are compute-bound, or else efficiency will decrease.

We recommend the [vLLM](https://vllm.ai/) inference server for this use case.
It is better able to schedule a mix of prefill and decode work,
which leads to higher throughput.

### High throughput LLM inference on Modal

The lack of latency constraints opens up a large number
of architectural choices for high throughput LLM inference.

For instance, values can be retrieved from an external datastore
or a [Modal Volume](/docs/guide/volumes)
based on identifiers or other information in the datastore.
This is particularly useful for
[cronjob deployments on Modal](/docs/guide/cron).
Results can then be placed back in that datastore.

Modal provides primitives for building a
[job queue](/docs/guide/job-queue)
that can scale to millions of pending inputs
and jobs that last up to a week.
In this case, the underlying LLM inference is provided by a
[Modal Cls](/docs/guide/lifecycle-functions)
invoked via
[`.spawn`](/docs/guide/job-queue).
Each call gets a string
[`modal.FunctionCall` identifier](/docs/sdk/py/latest/FunctionCall)
that can be used to query the result for up to a week.

The primary scaling limit from Modal in this case is the rate at which these calls can be queued.
If the inference system can complete more than 400 tasks per second,
we recommend batching multiple tasks into a single Function input until peak throughput
in tasks per second is serviced by 400 inputs per second.

See [this code sample](https://modal.com/docs/examples/vllm_throughput)
for a system that implements these recommendatons and
achieves maximal per-replica throughput.

## Minimizing LLM inference latency (TTFT/TPOT/TTLT)

The quintessential "low latency" LLM inference workload is a chatbot:
each request represents a waiting user, and users operate at the scale of a few hundred milliseconds.
Generating a token of usefully intelligent text often also takes on the order of milliseconds,
and users want many tokens in responses, so latency budgets are tight.

Performance is defined by *latency*, the time a given task spends waiting.
It is measured in time-to-first-token (TTFT) and time-per-output-token (TPOT)
or in time-to-last-token (TTLT),
depending on to what degree the application supports streaming responses.
For streaming applications, like most chatbots, TTFT matters most.

To whatever degree the application does support streaming, it is strongly recommended
to improve perceived latency by users.
Contemporary Transformer language models are sequential and so generate their responses
serially, leading to long gaps between the creation of the first token in a response and the last.

These long decode or token generation phases demand quite different performance
from hardware than long prefills do.
They are typically [memory-bound](https://modal.com/gpu-glossary/perf/memory-bound)
and so benefit from techniques that reduce the amount of memory loaded per token into the
[Streaming Multiprocessors](https://modal.com/gpu-glossary/device-hardware/streaming-multiprocessor)
or increase the amount of available
[memory bandwidth](https://modal.com/gpu-glossary/perf/memory-bandwidth).

Several techniques can reduce the amount of memory loaded per token:

* smaller and more aggressively [quantized](https://quant.exposed) models require less memory
* [speculative decoding](https://huggingface.co/docs/text-generation-inference/en/conceptual/speculation)
  generates multiple tokens at once via draft models

For memory-bound workloads, quantizing a model to a format not natively supported by the hardware
can still sometimes lead to gains.
The reduced demand on memory bandwidth cuts memory latency and there is generally sufficient unused
[arithmetic bandwidth](https://modal.com/gpu-glossary/perf/arithmetic-bandwidth)
to perform extra numerical conversions.

There are a wide variety of speculative decoding techniques, ranging from simple n-gram speculation
to stacks of models drafting tokens for each other in sequence.
We have generally found that the [EAGLE-3 method](https://arxiv.org/abs/2503.01840)
provides the best performance improvement for the least overhead --
computationally and operationally.
Generic draft models are available on Hugging Face,
but we have also seen major improvements from custom draft models
trained on sample production data using tools like
[SpecForge](https://lmsys.org/blog/2025-07-25-spec-forge/).

Additionally, using multiple GPUs to generate a single token increases the aggregate memory bandwidth,
at the cost of some extra communication.
Critically, multiple accelerators need to be used to load model weights in parallel,
or latency will not be reduced.
That means the usual form of parallelism used to reduce latency is *tensor parallelism*,
which splits up individual matrix multiplications across GPUs,
rather than *pipeline parallelism*,
which splits the entire model across GPUs.

There are few models below 70B parameters that work well in 4bit floating point
(with exceptions like [GPT-OSS](https://modal.com/docs/examples/gpt_oss_inference)).
Additionally, at time of writing in early 2026, there are not high-quality open source
Blackwell-optimized kernels for latency-sensitive LLM inference.
Therefore, we generally recommend FP8-quantized models on H100s or H200s.

Finally, we recommend the [SGLang](https://docs.sglang.io/)
inference engine for these workloads.
SGLang generally exhibits lower host overhead --
time when the GPU idles waiting on the CPU --
for decode-heavy workloads, especially for smaller models.
You can read more about host overhead and its solutions in
[this blog post](/blog/host-overhead-inference-efficiency).

### Low latency LLM inference on Modal

For latency budgets in the few hundreds of milliseconds,
network latencies and proxy/load-balancing overhead matter --
communicating with clients across an ocean takes dozens of milliseconds,
due to speed-of-light constraints.

Modal offers ultra-low-latency, regionalized web server deployment with
[Modal Servers](https://modal.com/docs/guide/servers#servers)
to reduce network overhead below 100ms.

You can find an example demonstrating all the pieces of
low latency LLM inference on Modal together
[here](https://modal.com/docs/examples/sglang_low_latency).

## High performance LLM inference for bursty workloads (cold start time)

The final major class of workloads sits between pure throughput and pure latency.
The quintessential application is a "workflow" where LLM inference is one workflow step,
and the workflow is sometimes run interactively by a human and at other times run asynchronously in bulk.

For these applications, the primary concern is handling the high
[peak-to-average load ratio](https://brooker.co.za/blog/2023/03/23/economics.html).
For instance, a pipeline might serve zero requests per second most of the time,
then ten for a bit, then one hundred, then back down to zero.
Statically provisioning enough resources to handle one hundred requests is clearly wasteful,
but spinning up new resources on demand incurs latency.

The key performance criterion, then, is
[*cold start time*](/docs/guide/cold-start):
how long does it take for a new replica to spin up and start handling requests.
On a typical cloud deployment, that includes instance requisition, machine boot, and container setup.
We've written about the resource allocation challenges [here](/blog/gpu-utilization-guide).

Approaches based on requesting resources from clouds directly take minutes to tens of minutes.
Modal has been designed from the kernel up to provide sub-second latencies
all the way through to container start.
From there, the primary performance concern is speeding up server startup.

* **Use small models and quantize aggressively**.
  Models can be loaded from a [Modal Volume](/docs/guide/volumes)
  at a rate of 1-2 GB/s. That means you're incurring nearly a second of cold start latency
  per gigabyte of model weights. More exotic compression formats, like integer quantization
  or even ternary quantization, are particularly helpful here, even when they don't improve
  latency during inference.

* **Skip compilation steps**.
  Optimizations like CUDA Graph capture, JIT-compiled kernels, and Torch compilation
  are great for improving latency and throughput but they are generally quite tricky to cache
  and cache hits sometimes take nearly as long as cache misses.
  That often means a large latency penalty from compilation on each boot,
  and latencies can easily range into the tens of seconds or even tens of minutes.

* **Restore from snapshots**.
  In some cases, startup-time work like JIT compilation is unavoidable.
  For these workloads, Modal provides
  [Memory Snapshots](/docs/guide/memory-snapshots):
  the full in-memory state of a container just before it is ready to
  handle requests is serialized to disk and future container starts
  only need to deserialize this back into memory.
  Modal includes support for
  [GPU Memory Snapshots](/blog/gpu-mem-snapshots)
  so that GPU-accelerated LLM inference servers can be snapshot as well.
  Memory snapshotting is powerful
  ([we've observed 10x reductions in cold start time](/blog/gpu-mem-snapshots)),
  but it requires some code modification, described below.

Which optimizations discussed above apply
depend on the balance of the workload between low latency and high throughput.
But a few general statements can be made.
For instance, speculative decoding is generally a bad choice,
since it harms performance in the high throughput regime.

Relatedly, we don't have a particular recommendation between vLLM and SGLang here.
Besides the points made above about host overhead latency vs bulk throughput,
the primary difference we have seen is that vLLM is a bit faster to market with new models
and new features, but SGLang is a bit easier to hack on and extend.

### Serving bursty LLM inference workloads on Modal

Modal's rapid autoscaling infrastructure,
from [the custom container runtime and filesystem](/blog/jono-containers-talk),
to [memory snapshot support](/blog/gpu-mem-snapshots),
is particularly well-suited
to bursty LLM inference workloads.

These workloads can either be served by vanilla
[Functions](/docs/guide/apps)
invoked via remote Python calls or as
[Web Functions](/docs/guide/webhooks)
invoked via HTTP.
Web Functions are better for integrating with a variety
of producers and consumers.
The tradeoff of lower overhead for increased complexity
with [Modal Servers](https://modal.com/docs/guide/servers#servers) is generally not worth it.

The [`@modal.concurrent` decorator](/docs/guide/concurrent-inputs)
supports setting both a limit (`max_inputs`)
and a target (`target_inputs`).
Set the limit higher than the target to absorb load increases into
existing capacity (typically at the expense of longer latency).
Make sure that the inference server is configured to handle batches as large as `max_inputs`
without internal queueing!

Almost all GPU programs can be snapshot, but most GPU programs
require some code changes to be snapshot.
For instance, both the vLLM and SGLang inference servers require
manual offloading of weights/KV cache to CPU memory before snapshotting.

For details, see our full sample code for running bursty workloads on Modal
with vLLM [here](https://modal.com/docs/examples/vllm_snapshot)
and with SGLang [here](https://modal.com/docs/examples/sglang_snapshot).
