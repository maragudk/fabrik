# CloudBucketMount


```python
class CloudBucketMount(object)
```

Mounts a cloud bucket to your container. Currently supports AWS S3 buckets.

S3 buckets are mounted using [AWS S3 Mountpoint](https://github.com/awslabs/mountpoint-s3).
S3 mounts are optimized for reading large files sequentially. It does not support every file operation; consult
[the AWS S3 Mountpoint documentation](https://github.com/awslabs/mountpoint-s3/blob/main/doc/SEMANTICS.md)
for more information.

**Usage**

S3:

```python
import subprocess

app = modal.App()
secret = modal.Secret.from_name(
    "aws-secret",
    required_keys=["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"]
    # Note: providing AWS_REGION can help when automatic detection of the bucket region fails.
)

@app.function(
    volumes={
        "/my-mount": modal.CloudBucketMount(
            bucket_name="s3-bucket-name",
            secret=secret,
            read_only=True
        )
    }
)
def f():
    subprocess.run(["ls", "/my-mount"], check=True)
```

R2:

Cloudflare R2 is [S3-compatible](https://developers.cloudflare.com/r2/api/s3/api/) so its setup looks
very similar to S3. But additionally the `bucket_endpoint_url` argument must be passed.

```python
import subprocess

app = modal.App()
secret = modal.Secret.from_name(
    "r2-secret",
    required_keys=["AWS_ACCESS_KEY_ID", "AWS_SECRET_ACCESS_KEY"]
)

@app.function(
    volumes={
        "/my-mount": modal.CloudBucketMount(
            bucket_name="my-r2-bucket",
            bucket_endpoint_url="https://<ACCOUNT ID>.r2.cloudflarestorage.com",
            secret=secret,
            read_only=True
        )
    }
)
def f():
    subprocess.run(["ls", "/my-mount"], check=True)
```

GCS:

Google Cloud Storage (GCS) is [S3-compatible](https://cloud.google.com/storage/docs/interoperability).
GCS Buckets also require a secret with Google-specific key names (see below) populated with
a [HMAC key](https://cloud.google.com/storage/docs/authentication/managing-hmackeys#create).

```python
import subprocess

app = modal.App()
gcp_hmac_secret = modal.Secret.from_name(
    "gcp-secret",
    required_keys=["GOOGLE_ACCESS_KEY_ID", "GOOGLE_ACCESS_KEY_SECRET"]
)

@app.function(
    volumes={
        "/my-mount": modal.CloudBucketMount(
            bucket_name="my-gcs-bucket",
            bucket_endpoint_url="https://storage.googleapis.com",
            secret=gcp_hmac_secret,
        )
    }
)
def f():
    subprocess.run(["ls", "/my-mount"], check=True)
```

```python
__init__(self, bucket_name, bucket_endpoint_url=None, key_prefix=None,
    secret=None, oidc_auth_role_arn=None, read_only=False, requester_pays=False,
    force_path_style=False)
```

