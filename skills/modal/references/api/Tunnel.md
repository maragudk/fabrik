# Tunnel


A port forwarded from within a running Modal container. Created by `modal.forward()`.

**Important:** This is an experimental API which may change in the future.

**Attributes**

<Parameter name="host" type="str" description="" />
<Parameter name="port" type="int" description="" />
<Parameter name="unencrypted_host" type="str" description="" />
<Parameter name="unencrypted_port" type="int" description="" />


## url

```python
url(self)
```
Get the public HTTPS URL of the forwarded port.

## tls_socket

```python
tls_socket(self)
```
Get the public TLS socket as a (host, port) tuple.

## tcp_socket

```python
tcp_socket(self)
```
Get the public TCP socket as a (host, port) tuple.
