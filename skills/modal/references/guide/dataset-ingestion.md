# Large dataset ingestion

This guide provides best practices for downloading, transforming, and storing large datasets within
Modal. A dataset is considered large if it contains hundreds of thousands of files and/or is over
100 GiB in size.

These guidelines ensure that large datasets can be ingested fully and reliably.

## Configure your Function for heavy disk usage

Large datasets should be downloaded and transformed using a `modal.Function` and stored
into a [Volume](/docs/guide/volumes).

This `modal.Function` should specify a large `timeout` because large dataset processing can take hours,
and it should request a larger ephemeral disk in cases where the dataset being downloaded and processed
is hundreds of GiBs.

```python
volume = modal.Volume.from_name("datasets", create_if_missing=True)


@app.function(
    volumes={"/mnt/datasets": volume},
    ephemeral_disk=1000 * 1000,  # 1 TiB
    timeout=60 * 60 * 12,  # 12 hours

)
def download_and_transform() -> None:
    ...
    volume.commit()
```

### Prefer sharded or archived outputs for tiny-file datasets

Volumes can store large datasets, but datasets made up of millions of tiny files are
still usually easier to ingest and consume when they are first grouped into larger artifacts such as
tar shards, WebDataset archives, Parquet files, or other batched formats.

See the [transforming](#transforming) section below for more details.

## Experimentation

Downloading and transforming large datasets can be fiddly. While iterating on a reliable ingestion program
you may want an interactive environment so you can inspect downloaded files, validate credentials,
and benchmark transforms before automating the full ingestion job. You can run a
[Jupyter server in a Sandbox](/docs/examples/jupyter_sandbox) for this. Attach the same Volume that your ingestion Functions use, keep transient scratch
data in `/tmp`, and persist intermediate artifacts under `/mnt/...`.

## Downloading

The raw dataset data should be first downloaded into the container at `/tmp/` and not placed
directly into the mounted volume. This serves a couple purposes.

1. Download tools often create temporary files, partial files, or rename targets while writing, and local SSD handles that more efficiently.
2. The raw dataset data may need to be transformed before use, in which case it is wasteful to store it permanently.

This snippet shows the basic download-and-copy procedure:

```python notest
import pathlib
import shutil
import subprocess

tmp_path = pathlib.Path("/tmp/imagenet/")
vol_path = pathlib.Path("/mnt/datasets/imagenet/")
filename = "imagenet-object-localization-challenge.zip"
# 1. Download into /tmp/
subprocess.run(
    f"kaggle competitions download -c imagenet-object-localization-challenge --path {tmp_path}",
    shell=True,
    check=True
)
vol_path.mkdir(parents=True, exist_ok=True)
# 2. Copy (without transform) into mounted volume.
shutil.copy2(tmp_path / filename, vol_path / filename)
volume.commit()
```

## Transforming

When ingesting a large dataset it is sometimes necessary to transform it before storage, so that it is in
an optimal format for loading at runtime. A common kind of necessary transform is gzip decompression. Very large
datasets are often gzipped for storage and network transmission efficiency, but gzip decompression (80 MiB/s)
is hundreds of times slower than reading from a solid state drive (SSD)
and should be done once before storage to avoid decompressing on every read against the dataset.

Transformations should be performed after storing the raw dataset in `/tmp/`. Performing transformations almost always increases container disk usage and this is where the [`ephemeral_disk` parameter](/docs/sdk/py/latest/App#function) parameter becomes important. For example, a
100 GiB raw, compressed dataset may decompress to into 500 GiB, occupying 600 GiB of container disk space.

Transformations should also typically be performed against `/tmp/`. This is because

1. transforms can be IO intensive and IO latency is lower against local SSD.
2. transforms can create temporary data which is wasteful to store permanently.

Once the transform is complete, write the final dataset layout to the attached Volume and commit it so
subsequent Functions and Sandboxes can reload and use the same data.

## Examples

The best practices offered in this guide are demonstrated in the [`modal-examples` repository](https://github.com/modal-labs/modal-examples/tree/main/12_datasets).

The examples include these popular large datasets:

* [ImageNet](https://www.image-net.org/), the image labeling dataset that kicked off the deep learning revolution
* [COCO](https://cocodataset.org/#download), the Common Objects in COntext dataset of densely-labeled images
* [LAION-400M](https://laion.ai/blog/laion-400-open-dataset/), the Stable Diffusion training dataset
* Data derived from the [Big "Fantastic" Database](https://bfd.mmseqs.com/),
  [Protein Data Bank](https://www.wwpdb.org/), and [UniProt Database](https://www.uniprot.org/)
  used in training the [RoseTTAFold](https://github.com/RosettaCommons/RoseTTAFold) protein structure model
