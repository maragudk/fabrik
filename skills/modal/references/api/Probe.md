# Probe


Probe configuration for the Sandbox Readiness Probe.

**Usage**

```python notest
# Wait until a file exists.
readiness_probe = modal.Probe.with_exec(
    "sh", "-c", "test -f /tmp/ready",
)

# Wait until a TCP port is accepting connections.
readiness_probe = modal.Probe.with_tcp(8080)

app = modal.App.lookup('sandbox-readiness-probe', create_if_missing=True)
sandbox = modal.Sandbox.create(
    "python3", "-m", "http.server", "8080",
    readiness_probe=readiness_probe,
    app=app,
)
sandbox.wait_until_ready()
```

**Attributes**

<Parameter name="tcp_port" type="int | None" defaultValue="None" description="" />
<Parameter name="exec_argv" type="tuple[str, ...] | None" defaultValue="None" description="" />
<Parameter name="interval_ms" type="int" defaultValue="100" description="" />


## with_tcp

```python
with_tcp(cls, port, *, interval_ms=100)
```


## with_exec

```python
with_exec(cls, *argv, interval_ms=100)
```

