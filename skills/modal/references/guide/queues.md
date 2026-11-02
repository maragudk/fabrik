# Queues

Modal Queues provide distributed FIFO queues to your Modal Apps.

```python runner:ModalRunner retry:2
import modal

app = modal.App()
queue = modal.Queue.from_name("simple-queue", create_if_missing=True)


def producer(x):
    queue.put(x)  # adding a value


@app.function()
def consumer():
    return queue.get()  # retrieving a value


@app.local_entrypoint()
def main(x="some object"):
    # produce and consume tasks from local or remote code
    producer(x)
    print(consumer.remote())
```

This page is a high-level guide to using Modal Queues.
For reference documentation on the `modal.Queue` object, see
[this page](/docs/sdk/py/latest/Queue).
For reference documentation on the `modal queue` CLI command, see
[this page](/docs/cli/latest/queue).

## Modal Queues are Python queues in the cloud

Like [Python `Queue`s](https://docs.python.org/3/library/queue.html),
Modal Queues are multi-producer, multi-consumer first-in-first-out (FIFO) queues.

Queues are particularly useful when you want to handle tasks or process
data asynchronously, or when you need to pass messages between different
components of your distributed system.

Queues are cleared 24 hours after the last `put` operation and are backed by
a replicated in-memory database, so persistence is likely, but not guaranteed.
As such, `Queue`s are best used for communication between active functions and
not relied on for persistent storage.

[Please get in touch](mailto:support@modal.com) if you need durability for Queue objects.

## Queues are partitioned by key

Queues are split into separate FIFO partitions via a string key. By default, one
partition (corresponding to an empty key) is used.

A single `Queue` can contain up to 100,000 partitions, each with up to 5,000
items. Each item can be up to 1 MiB, and each partition can be up to 64 MiB in
total size. These limits also apply to the default partition.

Each partition has an independent TTL, by default 24 hours.
Lower TTLs can be specified by the `partition_ttl` argument in the `put` or
`put_many` methods.

```python
with modal.Queue.ephemeral() as q:
    q.put("some value")  # first in
    q.put(123)

    assert q.get() == "some value"  # first out
    assert q.get() == 123

    q.put(0)
    q.put(1, partition="foo")
    q.put(2, partition="bar")

    # Default and "foo" partition are ignored by the get operation.
    assert q.get(partition="bar") == 2

    # Set custom 10s expiration time on "foo" partition.
    q.put(3, partition="foo", partition_ttl=10)

    # Iterate through items in place (read immutably)
    q.put(1)
    assert [v for v in q.iterate()] == [0, 1]
```

## You can access Modal Queues synchronously or asynchronously, blocking or non-blocking

Queues are synchronous and blocking by default. Consumers will block and wait
on an empty Queue and producers will block and wait on a full Queue,
both with an `Optional`, configurable `timeout`. If the `timeout` is `None`,
they will wait indefinitely. If a `timeout` is provided, `get` methods will raise
[`queue.Empty`](https://docs.python.org/3/library/queue.html#queue.Empty)
exceptions and `put` methods will raise
[`queue.Full`](https://docs.python.org/3/library/queue.html#queue.Full)
exceptions, both from the Python standard library.

The `get` and `put` methods can be made non-blocking by setting the `block` argument to `False`.
They raise `queue` exceptions without waiting on the `timeout`.

Queues are stored in the cloud, so all interactions require communication over the network.
This adds some extra latency to calls, apart from the `timeout`, on the order of tens of milliseconds.
To avoid this latency impacting application latency, you can asynchronously interact with Queues
by adding the `.aio` function suffix to access methods.

```python notest
@app.local_entrypoint()
async def main(value=None):
    await my_queue.put.aio(value or 200)
    assert await my_queue.get.aio() == value
```

See the guide to [asynchronous functions](/docs/guide/async) for more
information.

## Modal Queues are not *exactly* Python Queues

Python Queues can have values of any type.

Modal Queues can store Python objects of any serializable type.

Objects are serialized using [`cloudpickle`](https://github.com/cloudpipe/cloudpickle),
so precise support is inherited from that library. `cloudpickle` can serialize a surprising variety of objects,
like `lambda` functions or even Python modules, but it can't serialize a few things that don't
really make sense to serialize, like live system resources (sockets, writable file descriptors).

Note that you will need to have the library defining the type installed in the environment
where you retrieve the object so that it can be deserialized.
