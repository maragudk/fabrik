# Multi-node training

When you need maximum control over your training or fine-tuning loop and infrastructure, you can use a [Clustered Function](/docs/guide/multi-node-clusters).

This guide covers how to spin one up for frameworks based on [torchrun](https://docs.pytorch.org/docs/2.14/elastic/run.html) or [Ray](https://docs.ray.io/en/latest/index.html),
which supports [RDMA](/docs/guide/multi-node-clusters#rdma). See [here](/docs/examples/miles_grpo) for an example that does just that.

## torchrun

To use a torchrun-based framework on Modal, first create a container image with the [necessary dependencies](/docs/guide/multi-node-clusters#rdma) and [add your training script](/docs/guide/images#add-local-files-with-add_local_dir-and-add_local_file):

```python
LOCAL_CODE_DIR = "train"
REMOTE_CODE_DIR = "/root/train"
REMOTE_BENCH_SCRIPT_PATH = f"{REMOTE_CODE_DIR}/benchmark.py"

cuda_version = "12.4.0"  # should be no greater than host CUDA version
flavor = "devel"  #  includes full CUDA toolkit
operating_sys = "ubuntu22.04"
tag = f"{cuda_version}-{flavor}-{operating_sys}"

image = (
    modal.Image.from_registry(f"nvidia/cuda:{tag}", add_python="3.12")
    .apt_install("libibverbs1")
    .uv_pip_install("torch")
    .add_local_dir(
        LOCAL_CODE_DIR,
        remote_path=REMOTE_CODE_DIR,
    )
)
```

Then, create a Clustered Function with RDMA configured and start `torchrun` with the training script. In this example, we create a two-node cluster with eight H100s per node:

```python continuation
N_NODES = 2
N_GPUS_PER_NODE = 8

@app.function(
    gpu=f"H100:{N_GPUS_PER_NODE}",
    image=image,
    timeout=60 * 60,
)
@modal.clustered(size=N_NODES, rdma=True)
def run():
    from torch.distributed.run import parse_args, run

    cluster = modal.Cluster.from_context()
    args = [
        f"--nnodes={N_NODES}",
        f"--nproc-per-node={N_GPUS_PER_NODE}",
        f"--node-rank={cluster.container_rank()}",
        f"--master-addr={cluster.container_ips()[0]}",
        REMOTE_BENCH_SCRIPT_PATH,
    ]

    run(parse_args(args))
```

Be sure to set the appropriate [GPU type](/docs/guide/gpu) and [timeout](/docs/guide/timeouts) for your workload.
Clusters must use the [full number of GPU devices per node](/docs/guide/gpu#specifying-gpu-count).

## Ray

To set up a [Ray cluster](https://docs.ray.io/en/latest/index.html) on a Clustered Function, gather information about the cluster and IPv4 addresses from `modal.Cluster.from_context()`.
Then, start a head node on rank 0 and a worker node on other ranks:

```python continuation
N_NODES = 2
N_GPUS_PER_NODE = 8

@app.function(
    gpu=f"H100:{N_GPUS_PER_NODE}",
    image=image,
    timeout=24 * 60 * 60,
)
@modal.clustered(size=N_NODES, rdma=True)
async def train():
    cluster = modal.Cluster.from_context()
    ips = cluster.container_ips(family="ipv4")
    rank = cluster.container_rank()

    my_ip = ips[rank]
    head_ip = ips[0]

    # Set any environment variables needed for Ray itself here...
    os.environ["HOST_IP"] = my_ip

    if rank == 0:
        await run_head(my_ip)
    else:
        await run_worker(my_ip, head_ip)
```

<Callout variant="info">

Ray only works with IPv4. Be sure to set `family="ipv4"` when you request IP addresses for containers.

</Callout>

Rank 0 should launch a Ray head node and wait for it to start up. Once it does, it can construct a train command and submit it to the cluster, then keep itself alive while forwarding logs:

```python
async def run_head(my_ip):
    import ray
    from ray.job_submission import JobSubmissionClient

    subprocess.Popen(
        [
            "ray",
            "start",
            "--head",
            f"--node-ip-address={my_ip}",
            "--dashboard-host=0.0.0.0",
        ]
    )

    # Wait for the Ray head to start up
    for _ in range(30):
        try:
            ray.init(address="auto")
            break
        except Exception:
            await asyncio.sleep(1)
    else:
        raise RuntimeError("Failed to connect to Ray head")

    cmd = build_train_cmd()
    runtime_env = {
        "env_vars": {
            "no_proxy": f"127.0.0.1,{my_ip}",
            "MASTER_ADDR": my_ip,
            # Any other environment variables for your workload...
        }
    }

    client = JobSubmissionClient("http://127.0.0.1:8265")
    job_id = client.submit_job(entrypoint=cmd, runtime_env=runtime_env)

    # Forward logs to the Modal dashboard
    async with modal.forward(8265) as tunnel:
        print(f"Ray dashboard: {tunnel.url}")
        async for line in client.tail_job_logs(job_id):
            print(line, end="", flush=True)
```

Other ranks simply start Ray as a worker node and provide it the IP of the head node. They then loop to keep themselves alive while the job runs:

```python
async def run_worker(my_ip, head_ip):
    subprocess.Popen(
        [
            "ray",
            "start",
            f"--node-ip-address={my_ip}",
            "--address",
            f"{head_ip}:6379",
        ]
    )

    while True:
        await asyncio.sleep(10)
```
