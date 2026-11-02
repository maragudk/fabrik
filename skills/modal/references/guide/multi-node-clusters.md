# Multi-node Clusters

Modal Clusters supports petaFLOP/s jobs that run across several coordinated containers, such as serving or training trillion-parameter models. Each container can saturate the available GPU devices on its node and communicate with peer containers for terabit/s networking.

Modal Clusters provide:

* A [secure private network](https://modal.com/docs/guide/private-networking) for orchestration.
* A 6,400 Gbps (B300) or 3,200 Gbps (other GPUs) RDMA scale-out network ([RoCE](https://en.wikipedia.org/wiki/RDMA_over_Converged_Ethernet), [InfiniBand](https://en.wikipedia.org/wiki/InfiniBand), or [EFA](https://aws.amazon.com/hpc/efa/)).
* Up to 32 nodes and 256 GPUs per cluster. [Contact us](mailto:support@modal.com) for even larger clusters.
* Deep burn-in testing and [continuous GPU and network health monitoring](https://modal.com/blog/gpu-health).
* Interoperability with all Modal platform functionality ([Volumes](/docs/guide/volumes), [Dicts](/docs/guide/dicts), [Tunnels](/docs/guide/tunnels), etc.).

When you call a Clustered [Function](https://modal.com/docs/guide/functions) or [Server](https://modal.com/docs/guide/servers), Modal starts multiple containers simultaneously, then runs your code in each container. Therefore, your code should establish communication between containers and coordinate with each other to deliver the final result.

The guide will walk you through how to fully take advantage of Modal Clusters. To learn how to use common training frameworks with Clusters, see the [multi-node training guide](https://modal.com/docs/guide/multi-node-training).

## Using the `@clustered` decorator

To make a Clustered Function or Server, use the `@clustered` decorator:

```python
@app.function(
    gpu="H100:8",
    timeout=60 * 60 * 24,
    retries=modal.Retries(initial_delay=0.0, max_retries=10),
)
@modal.clustered(size=4)
def train_model():
    cluster = modal.Cluster.from_context()

    container_rank = cluster.container_rank()
    container_ips = cluster.container_ips()
    world_size = len(container_ips)
    main_addr = container_ips[0]
    is_main = "(main)" if container_rank == 0 else ""

    print(f"{container_rank=} {is_main} {world_size=} {main_addr=}")
```

The above configuration creates a group of four containers each having eight H100 GPU devices, for a total of 32 devices.

Containers in a multi-node cluster are physically colocated and [gang scheduled](https://en.wikipedia.org/wiki/Gang_scheduling) together so that your code only runs once all of the requested hardware is acquired.

Traditionally this kind of cluster and scheduling management would be handled by SLURM, Kubernetes, or something else. But with Modal, it's all provided serverlessly with just a Python decorator!

<Callout variant="info">

Clustered functions must use the [full number of GPUs per node](https://modal.com/docs/guide/gpu#specifying-gpu-count). For example, `H100:4` is invalid, but `H100:8` is valid. CPU-only clustered functions are not supported.

</Callout>

The `@modal.clustered` decorator also supports [Functions defined as a class](https://modal.com/docs/guide/lifecycle-functions) using `@app.cls()`, provided the class exposes exactly one method.

Web Functions are not supported. For HTTP workloads, use a [Server](https://modal.com/docs/guide/servers).

## Autoscaling

Modal's [autoscaler](https://modal.com/docs/guide/scale) handles scaling up and scaling down by entire clusters at a time. As with typical Functions, you can [configure this behavior](https://modal.com/docs/guide/scale#configuring-autoscaling-behavior) to control how many clusters can run at a given time.

`min_containers`, `max_containers`, and `buffer_containers` count **individual nodes** and must be multiples of the cluster size. For example, if you declare a four-node cluster, `min_containers=8` would tell the autoscaler to keep a minimum of two clusters running, for a total of eight containers.

## Rank & input broadcast

Each container in a multi-node cluster is assigned a rank. Rank zero is the "leader" rank, or head node, and typically coordinates the job.

To get the current container's rank:

```python notest
cluster = modal.Cluster.from_context()
container_rank = cluster.container_rank()
if container_rank == 0:
    print("Running as the leader")
else:
    print(f"Running as rank {container_rank}")
```

When you call a Clustered [Function](https://modal.com/docs/guide/functions), each container receives a copy of the Function call's arguments. For example, if you call a four-node Function, your code will run four times in parallel across four containers.

For Clustered [Servers](https://modal.com/docs/guide/servers), network traffic is routed only to rank zero, which is then responsible for distributing requests to the other containers.

Only rank zero's output is returned to the caller; i.e., outputs from other ranks are discarded. To share work before returning a final result, use [inter-container networking](#networking) or [RDMA](#rdma).

## Networking

In addition to gang scheduling, the `@clustered` decorator enables [i6pn](/docs/guide/private-networking), Modal’s workspace-private inter-container networking, so that containers in a cluster can communicate with each other over TCP or UDP. You can then use protocols such as [Torch Distributed Elastic](https://docs.pytorch.org/docs/2.14/elastic/rendezvous.html) on top of Modal’s networking stack. Private networking is available whether or not [RDMA](#rdma) is enabled.

[`Cluster.container_ips()`](/docs/sdk/py/latest/Cluster#container_ips) returns one IP address per container, ordered by rank, for intra-cluster communication.

```python notest
cluster = modal.Cluster.from_context()
container_ips = cluster.container_ips()
print(f"The main container's IP is {container_ips[0]}")
```

By default, `container_ips()` returns IPv6 addresses. For workloads that require IPv4 (such as Ray-based frameworks), pass in the `family` parameter:

```python notest
cluster = modal.Cluster.from_context()
container_ips = cluster.container_ips(family="ipv4")
print(f"The main container's IP is {container_ips[0]}")
```

For more on what you can do with inter-container networking, see the [cluster networking guide](https://modal.com/docs/guide/private-networking).

## RDMA

For even higher inter-node bandwidth, you can enable RDMA. The exact bandwidth depends on GPU type: B300 clusters have 6,400 Gbps networking, while other GPU types have 3,200 Gbps.

RDMA is supported on H100, H200, B200, B300, and GB200 GPUs.

To use RDMA, make sure your container image contains the necessary dependencies, typically a copy of `libcudart.so`, `libibverbs.so.1`, and `libmlx5.so.1`. The easiest way to do this is to [use a CUDA base image](/docs/guide/cuda#for-more-complex-setups-use-an-officially-supported-cuda-image), then `.apt_install` the InfiniBand library:

```python
cuda_version = "12.9.1"
flavor = "devel"
operating_sys = "ubuntu22.04"
tag = f"{cuda_version}-{flavor}-{operating_sys}"

image = (
    modal.Image.from_registry(f"nvidia/cuda:{tag}", add_python="3.12")
    .apt_install("libibverbs1")
)
```

Then, pass in `rdma=True` to the `clustered` decorator:

```python notest
@modal.clustered(size=2, rdma=True)
def train():
    ...
```

If you're using [NCCL](https://developer.nvidia.com/nccl) or a framework based on it, Modal automatically sets the necessary environment variables in your containers.

Otherwise, Modal exposes one of two RDMA interfaces, depending on the underlying hardware: InfiniBand Verbs or [EFA](https://aws.amazon.com/hpc/efa/). If your workload is not compatible with EFA, you can force your container to run on an InfiniBand Verbs host using the `efa_disabled` experimental option:

```python notest
@app.function(
    ...,
    experimental_options={
        "efa_disabled": True,
    },
)
@modal.clustered(size=2, rdma=True)
def train():
    ...
```

<Callout variant="warning">

Setting the `efa_disabled` option may impact scheduling times and availability of capacity.

</Callout>

To run a simple RDMA performance test, see [this sample code](https://github.com/modal-labs/multinode-training-guide/tree/main/benchmark).

## Fault tolerance

Failures are propagated to other containers. If an input fails on any individual container, Modal will terminate all remaining containers and mark the entire call as failed, even if the input succeeded on another container. You can set a [retry policy](https://modal.com/docs/guide/retries) to have Modal retry the input for you.

[Preemptions](/docs/guide/preemption) apply to the entire cluster. In the event of a preemption, Modal will terminate all containers in the cluster and retry it with the same input.

### Input synchronization

<Callout variant='info'>

Synchronization is not relevant for single training runs, and applies mostly to inference use-cases.

</Callout>

Modal does not synchronize input execution across containers. Containers are responsible for ensuring that they do not process inputs faster than other containers in their cluster.

In particular, it is important that the leader container (rank 0) waits for all other containers to finish processing the current input before starting the next one.
