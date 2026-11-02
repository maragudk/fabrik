# Volumes

Volumes are a high-performance distributed file system for Modal applications. They are optimized for write-once, read-many I/O workloads, like creating machine learning model weights and distributing them for inference.

Key benefits:

* Volumes are distributed by default, so you can use them alongside Modal’s global compute pool without needing to manage replicas across regions.
* Volumes have caching and chunking optimizations built-in to maximize throughput.
* Volumes come with a fully-featured filesystem interface for easy integration into your favorite ML tools and frameworks.
* Volumes are backed by multiple underlying cloud providers to guarantee high availability.

This page is a high-level guide to using Modal Volumes.
For reference documentation on the `modal.Volume` object, see
[this page](/docs/sdk/py/latest/Volume).
For reference documentation on the `modal volume` CLI command, see
[this page](/docs/cli/latest/volume).

## Pricing

Please refer to our [pricing page](/pricing) for up-to-date prices. We calculate usage by snapshotting your total storage once a day. When you delete data, you may still be billed for that storage for up to four days, to reflect our underlying processing costs.

## Volumes v2

There are two versions of Volumes. We recommend Volumes v2 for all new Volumes:
it supports more files, higher throughput, concurrent writes from hundreds of
containers, and is HIPAA compliant.

Volumes v1 is still the default when no version is specified, so pass
`version=2` (or `--version=2` on the command line) when creating a Volume.

Read more about [Volumes v2](#volumes-v2-overview) below. Instructions specific to v2 Volumes will be annotated with 🌱.

## Creating a Volume

The easiest way to create a Volume and use it as a part of your App is to use
the [`modal volume create`](/docs/cli/latest/volume#modal-volume-create) CLI command. This will create the Volume and output
some sample code:

```bash
% modal volume create my-volume
Created volume 'my-volume' in environment 'main'.
```

> 🌱 To create a v2 Volume, pass `--version=2` in the command above.

## Using a Volume on Modal

To attach an existing Volume to a Modal Function, use [`Volume.from_name`](/docs/sdk/py/latest/Volume#from_name):

```python
vol = modal.Volume.from_name("my-volume")


@app.function(volumes={"/data": vol})
def run():
    with open("/data/xyz.txt", "w") as f:
        f.write("hello")
    vol.commit()  # Needed to make sure all changes are persisted before exit
```

You can also browse and manipulate Volumes from an ad hoc Modal Shell:

```bash
% modal shell --volume my-volume --volume another-volume
```

Volumes will be mounted under `/mnt`.

Volumes are designed to provide up to 2.5 GB/s of bandwidth.
Actual throughput is not guaranteed and may be lower depending on network conditions.

## Mount options

When attaching a Volume to a Function or Sandbox, you can configure mount options using
[`Volume.with_mount_options`](/docs/sdk/py/latest/Volume#with_mount_options).
These options are not stored on the Volume itself — they apply per container mount,
so the same Volume can be mounted differently for distinct containers.

### Read-only mounts

To prevent a container from writing to a Volume, mount it in read-only mode:

```python notest
import modal

volume = modal.Volume.from_name("my-volume")

sb = modal.Sandbox.create(
    volumes={"/data": volume.with_mount_options(read_only=True)},
    app=app,
)
sb.exec("cat", "/data/config.json").wait()  # ok!
sb.exec("touch", "/data/new-file").wait()  # error!
```

### Mounting a sub-path

You can mount a subdirectory of a Volume instead of the entire Volume using the `sub_path` mount option.
If the subdirectory doesn't exist yet, it will be created when the container starts.

```python notest
import modal

volume = modal.Volume.from_name("my-volume")

sb = modal.Sandbox.create(
    volumes={"/user_data": volume.with_mount_options(sub_path="/users/user_123")},
    app=app,
)
# /user_data inside of the contianer is now referencing /users/user_123 in the Volume
sb.exec("ls", "/user_data").wait()
```

Sub-path mounting is especially useful when you want a single Volume to serve
multiple end user sessions, but don't want a session to access or even see
files for other sessions in the Volume.

**Note:** Sub-path is currently restricted to directories - you can not mount an individual file.

## Downloading a file from a Volume

While there’s no file size limit for individual files in a volume, the frontend only supports downloading files up to 16 MB. For larger files, please use the CLI:

```bash
% modal volume get my-volume xyz.txt xyz-local.txt
```

### Creating Volumes lazily from code

You can also create Volumes lazily from code using:

```python
vol = modal.Volume.from_name("my-volume", create_if_missing=True)
```

> 🌱 To create a v2 Volume, pass `version=2` to the call to `from_name()` in the code above.

This will create the Volume if it doesn't exist.

## Using a Volume from outside of Modal

Volumes can also be used outside Modal via the [Python SDK](/docs/sdk/py/latest/Volume) or our [CLI](/docs/cli/latest/volume).

### Using a Volume from local code

You can interact with Volumes from anywhere you like using the `modal` Python client library.

```python notest
vol = modal.Volume.from_name("my-volume")

with vol.batch_upload() as batch:
    batch.put_file("local-path.txt", "/remote-path.txt")
    batch.put_directory("/local/directory/", "/remote/directory")
    batch.put_file(io.BytesIO(b"some data"), "/foobar")
```

For more details, see the [reference documentation](/docs/sdk/py/latest/Volume).

### Using a Volume via the command line

You can also interact with Volumes using the command line interface. You can run
`modal volume` to get a full list of its subcommands:

```bash
% modal volume
Usage: modal volume [OPTIONS] COMMAND [ARGS]...

 Read and edit modal.Volume volumes.
 Note: users of modal.NetworkFileSystem should use the modal nfs command instead.

╭─ Options ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ --help          Show this message and exit.                                                                                                                                                            │
╰────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
╭─ File operations ──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ cp       Copy within a modal.Volume. Copy source file to destination file or multiple source files to destination directory.                                                                           │
│ get      Download files from a modal.Volume object.                                                                                                                                                    │
│ ls       List files and directories in a modal.Volume volume.                                                                                                                                          │
│ put      Upload a file or directory to a modal.Volume.                                                                                                                                                 │
│ rm       Delete a file or directory from a modal.Volume.                                                                                                                                               │
╰────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
╭─ Management ───────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╮
│ create   Create a named, persistent modal.Volume.                                                                                                                                                      │
│ delete   Delete a named, persistent modal.Volume.                                                                                                                                                      │
│ list     List the details of all modal.Volume volumes in an Environment.                                                                                                                               │
╰────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────╯
```

For more details, see the [reference documentation](/docs/cli/latest/volume).

## Volume commits and reloads

Unlike a normal filesystem, you need to explicitly reload the Volume to see
changes made since it was first mounted. This reload is handled by invoking the
[`.reload()`](/docs/sdk/py/latest/Volume#reload) method on a Volume object.
Similarly, any Volume changes made within a container need to be committed for
those the changes to become visible outside the current container. This is handled
periodically by [background commits](#background-commits) and directly by invoking
the [`.commit()`](/docs/sdk/py/latest/Volume#commit)
method on a `modal.Volume` object.

At container creation time the latest state of an attached Volume is mounted. If
the Volume is then subsequently modified by a commit operation in another
running container, that Volume modification won't become available until the
original container does a [`.reload()`](/docs/sdk/py/latest/Volume#reload).

Consider this example which demonstrates the effect of a reload:

```python
import pathlib
import modal

app = modal.App()

volume = modal.Volume.from_name("my-volume")

p = pathlib.Path("/root/foo/bar.txt")


@app.function(volumes={"/root/foo": volume})
def f():
    p.write_text("hello")
    print(f"Created {p=}")
    volume.commit()  # Persist changes
    print(f"Committed {p=}")


@app.function(volumes={"/root/foo": volume})
def g(reload: bool = False):
    if reload:
        volume.reload()  # Fetch latest changes
    if p.exists():
        print(f"{p=} contains '{p.read_text()}'")
    else:
        print(f"{p=} does not exist!")


@app.local_entrypoint()
def main():
    g.remote()  # 1. container for `g` starts
    f.remote()  # 2. container for `f` starts, commits file
    g.remote(reload=False)  # 3. reuses container for `g`, no reload
    g.remote(reload=True)   # 4. reuses container, but reloads to see file.
```

The output for this example is this:

```
p=PosixPath('/root/foo/bar.txt') does not exist!
Created p=PosixPath('/root/foo/bar.txt')
Committed p=PosixPath('/root/foo/bar.txt')
p=PosixPath('/root/foo/bar.txt') does not exist!
p=PosixPath('/root/foo/bar.txt') contains hello
```

This code runs two containers, one for `f` and one for `g`. Only the last
function invocation reads the file created and committed by `f` because it was
configured to reload.

### Background commits

Modal Volumes run background commits:
every few seconds while your Function or Sandbox executes,
the contents of attached Volumes will be committed
without your application code calling `.commit`.
A final snapshot and commit is also automatically performed on container shutdown.

Being able to persist changes to Volumes without changing your application code
is especially useful when [training or fine-tuning models using frameworks](#model-checkpointing).

## Model serving

A single ML model can be served by simply baking it into a `modal.Image` at
build time using [`run_function`](/docs/sdk/py/latest/Image#run_function). But
if you have dozens of models to serve, or otherwise need to decouple image
builds from model storage and serving, use a `modal.Volume`.

Volumes can be used to save a large number of ML models and later serve any one
of them at runtime with great performance. This snippet below shows the
basic structure of the solution.

```python
import modal

app = modal.App()
volume = modal.Volume.from_name("model-store")
model_store_path = "/vol/models"


@app.function(volumes={model_store_path: volume}, gpu="any")
def run_training():
    model = train(...)
    save(model_store_path, model)
    volume.commit()  # Persist changes


@app.function(volumes={model_store_path: volume})
def inference(model_id: str, request):
    try:
        model = load_model(model_store_path, model_id)
    except NotFound:
        volume.reload()  # Fetch latest changes
        model = load_model(model_store_path, model_id)
    return model.run(request)
```

For more details, see our [guide to storing model weights on Modal](/docs/guide/model-weights).

## Model checkpointing

Checkpoints are snapshots of an ML model and can be configured by the callback
functions of ML frameworks. You can use saved checkpoints to restart a training
job from the last saved checkpoint. This is particularly helpful in managing
[preemption](/docs/guide/preemption).

For more, see our [example code for long-running training](/docs/examples/long-training).

### Hugging Face `transformers`

To periodically checkpoint into a `modal.Volume`, just set the `Trainer`'s
[`output_dir`](https://huggingface.co/docs/transformers/main/en/main_classes/trainer#transformers.TrainingArguments.output_dir)
to a directory in the Volume.

```python
import pathlib

volume = modal.Volume.from_name("my-volume")
VOL_MOUNT_PATH = pathlib.Path("/vol")

@app.function(
    gpu="A10G",
    timeout=2 * 60 * 60,  # run for at most two hours
    volumes={VOL_MOUNT_PATH: volume},
)
def finetune():
    from transformers import Seq2SeqTrainer
    ...

    training_args = Seq2SeqTrainingArguments(
        output_dir=str(VOL_MOUNT_PATH / "model"),
        # ... more args here
    )

    trainer = Seq2SeqTrainer(
        model=model,
        args=training_args,
        train_dataset=tokenized_xsum_train,
        eval_dataset=tokenized_xsum_test,
    )
```

## Volume performance

Volumes work best when they contain less than 50,000 files and directories. The
latency to attach or modify a Volume scales linearly with the number of files in
the Volume, and past a few tens of thousands of files the linear component
starts to dominate the fixed overhead.

There is currently a hard limit of 500,000 inodes (files, directories and
symbolic links) per Volume. If you reach this limit, any further attempts to
create new files or directories will error with
[`ENOSPC` (No space left on device)](https://pubs.opengroup.org/onlinepubs/9799919799/).

If you need to work with a large number of files, consider using Volumes v2!

## Filesystem consistency

### Concurrent modification

Concurrent modification from multiple containers is supported, but concurrent
modifications of the same files should be avoided. Last write wins in case of
concurrent modification of the same file — any data the last writer didn't have
when committing changes will be lost!

The number of commits you can run concurrently is limited. If you run too many
concurrent commits each commit will take longer due to contention. If you are
committing small changes, avoid doing more than 5 concurrent commits (the number
of concurrent commits you can make is proportional to the size of the changes
being committed).

As a result, Volumes are typically not a good fit for use cases where you need
to make concurrent modifications to the same file (nor is distributed file
locking supported).

While a reload is in progress the Volume will appear empty to the container that
initiated the reload. That means you cannot read from or write to a Volume in a
container where a reload is ongoing (note that this only applies to the
container where the reload was issued, other containers remain unaffected).

### Busy Volume errors

You can only reload a Volume when there no open files on the Volume. If you have
open files on the Volume the [`.reload()`](/docs/sdk/py/latest/Volume#reload)
operation will fail with "volume busy". The following is a simple example of how
a "volume busy" error can occur:

```python
volume = modal.Volume.from_name("my-volume")


@app.function(volumes={"/vol": volume})
def reload_with_open_files():
    f = open("/vol/data.txt", "r")
    volume.reload()  # Cannot reload when files in the Volume are open.
```

### Can't find file on Volume errors

When accessing files in your Volume, don't forget to pre-pend where your Volume
is mounted in the container.

In the example below, where the Volume has been mounted at `/data`, "hello" is
being written to `/data/xyz.txt`.

```python
import modal

app = modal.App()
vol = modal.Volume.from_name("my-volume")


@app.function(volumes={"/data": vol})
def run():
    with open("/data/xyz.txt", "w") as f:
        f.write("hello")
    vol.commit()
```

If you instead write to `/xyz.txt`, the file will be saved to the local disk of the Modal Function.
When you dump the contents of the Volume, you will not see the `xyz.txt` file.

## Disk usage reporting

Modal Volumes are not block devices and do not have a fixed capacity.
Additionally, used space is not currently reported at the filesystem level.
As a result, tools that query disk usage via the `statfs` syscall
(e.g. `shutil.disk_usage()`, `os.statvfs()`, `df`) will return placeholder
values.

If you need to check the size of a Volume, refer to the size shown in the Modal
dashboard, or use `du` on the mounted Volume within a container.

## Volumes v2 overview

Volumes v2 generally behave just like Volumes v1, and most of the existing APIs
and CLI commands that you are used to will work the same between versions.
Because the file system implementation is completely different, there will be
some significant performance characteristics that can differ from v1
Volumes. Below is an outline of the key differences you should be aware of.

### Volumes v2 are HIPAA compliant

If you delete the volume, the data is guaranteed to be lost according to HIPAA requirements.

### Volumes v2 is more scaleable

Volumes v2 support more files, higher throughput, and more irregular access
patterns. Commits and reloads are also faster.

Additionally, Volumes v2 supports hard-linking of files, where multiple paths
can point to the same inode.

### In v2, you can store as many files as you want

There is no limit on the number of files in Volumes v2.

By contrast, in Volumes v1, there is a limit on the number of files of 500,000,
and we recommend keeping the count to 50,000 or less.

### In v2, you can write concurrently from hundreds of containers

The file system should not experience any performance degradation as more
containers write to distinct files simultaneously.

By contrast, in Volumes v1, we recommend no more than five writers access the
Volume at once.

Note, however, that concurrent access to a particular *file* in a Volume still
has last-write-wins semantics in many circumstances. These semantics are
unacceptable for most applications, so any particular file should only be
written to by a single container at a time.

### In v2, random accesses have improved performance

In v1, writes to locations inside a file would sometimes incur substantial
overhead, like a rewrite of the entire file.

In v2, this overhead is removed, and only changes are written.

### In v2, you can commit using `sync`

For Volumes v2, you can trigger a commit from within a Sandbox or modal shell
by running the `sync` command on the mountpoint:

```bash
sync /path/to/mountpoint
```

This is useful when you don't have access to the Python SDK's
[`.commit()`](/docs/sdk/py/latest/Volume#commit) method, such as when running
shell commands in a Sandbox or during an interactive `modal shell` session.

Running `sync` on the mountpoint will flush any pending writes to the kernel
and then persist all data and metadata changes to the Volume's persistent
storage.

For example, to commit changes in a modal shell session:

```bash
% modal shell --volume my-v2-volume
root / → echo "hello" > /mnt/my-v2-volume/test.txt
root / → sync /mnt/my-v2-volume  # Persist changes before exiting
```

Or to commit from within a Sandbox:

```python notest
sb = modal.Sandbox.create(
    volumes={"/data": modal.Volume.from_name("my-v2-volume")},
    app=my_app,
)
sb.exec("bash", "-c", "echo 'hello' > /data/test.txt").wait()

# Persist changes and check for errors
p = sb.exec("sync", "/data")
p.wait()
if p.returncode != 0:
    raise Exception(f"sync failed with exit code {p.returncode}")
```

### Volumes v2 limits

* Files must be less than 1 TiB.
* At most 262,144 files can be stored in a single directory.
  Directory depth is unbounded, so the total file count is unbounded.
* Traversing the filesystem can be slower in v2 than in v1, due to demand
  loading of the filesystem tree.

### Upgrading v1 Volumes

Currently, there is no automated tool for upgrading v1 Volumes to v2. v1 Volumes
need to be manually migrated by creating a new v2 Volume and either copying files
over from the v1 Volume or writing new files.

To reuse the name of an existing v1 Volume for a new v2 Volume, first stop all
Apps that are utilizing the v1 Volume before deleting it. If this is not
feasible, e.g. due to wanting to avoid downtime, use a new name for the v2
Volume.

**Warning:** When deleting an existing Volume, any deployed Apps or running
Functions utilizing that Volume will cease to function, even if a new Volume is
created with the same name. This is because Volumes are identified with opaque
unique IDs that are resolved at application deployment or start time. A newly
created Volume with the same name as a deleted Volume will have a new Volume ID
and any deployed or running Apps will still be referring to the old ID until
these Apps are re-deployed or restarted.

In order to create a new Volume and copy data over from the old Volume, you can
use a tool like `cp` if you intend to copy all the data in one go, or `rsync`
if you want to incrementally copy the data across a longer time span:

```shell
$ modal volume create --version=2 2files2furious
$ modal shell --volume files-and-furious --volume 2files2furious
Welcome to Modal's debug shell!
We've provided a number of utilities for you, like `curl` and `ps`.
# Option 1: use `cp`
root / → cp -rp /mnt/files-and-furious/. /mnt/2files2furious/.
root / → sync /mnt/2files2furious # Ensure changes are persisted before exiting

# Option 2: use `rsync`
root / → apt install -y rsync
root / → rsync -a /mnt/files-and-furious/. /mnt/2files2furious/.
root / → sync /mnt/2files2furious # Ensure changes are persisted before exiting
```

## Further examples

* [LLM post-training with Miles and GRPO](/docs/examples/miles_grpo) with datasets and checkpoints on Volumes
* [Protein folding](/docs/examples/chai1) with model weights and output files stored on Volumes
* [Dataset visualization with Datasette](/docs/examples/cron_datasette) using a SQLite database on a Volume
