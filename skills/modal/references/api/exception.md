# exception

Modal-specific exception types.

**Notes on `grpclib.GRPCError` migration**

Historically, the Modal SDK could propagate `grpclib.GRPCError` exceptions out
to user code.  As of v1.3, we are in the process of gracefully migrating to
always raising a Modal exception type in these cases. To avoid breaking user
code that relies on catching `grpclib.GRPCError`, a subset of Modal exception
types temporarily inherit from `grpclib.GRPCError`.

We encourage users to migrate any code that currently catches `grpclib.GRPCError`
to instead catch the appropriate Modal exception type. The following mapping
between GRPCError status codes and Modal exception types is currently in use:

```
CANCELLED -> ServiceError
UNKNOWN -> ServiceError
INVALID_ARGUMENT -> InvalidError
DEADLINE_EXCEEDED -> ServiceError
NOT_FOUND -> NotFoundError
ALREADY_EXISTS -> AlreadyExistsError
PERMISSION_DENIED -> PermissionDeniedError
RESOURCE_EXHAUSTED -> ResourceExhaustedError
FAILED_PRECONDITION -> ConflictError
ABORTED -> ConflictError
OUT_OF_RANGE -> InvalidError
UNIMPLEMENTED -> UnimplementedError
INTERNAL -> InternalError
UNAVAILABLE -> ServiceError
DATA_LOSS -> DataLossError
UNAUTHENTICATED -> AuthError
```

## AlreadyExistsError


```python
class AlreadyExistsError(modal.exception.Error, modal.exception._GRPCErrorWrapper)
```

Raised when a resource creation conflicts with an existing resource.

## AsyncUsageWarning


```python
class AsyncUsageWarning(UserWarning)
```

Warning emitted when a blocking Modal interface is used in an async context.

## AuthError


```python
class AuthError(modal.exception.Error, modal.exception._GRPCErrorWrapper)
```

Raised when a client has missing or invalid authentication.

## ClientClosed


```python
class ClientClosed(modal.exception.Error)
```

## ConflictError


```python
class ConflictError(modal.exception.InvalidError, modal.exception._GRPCErrorWrapper)
```

Raised when a resource conflict occurs between the request and current system state.

## ConnectionError


```python
class ConnectionError(modal.exception.Error)
```

Raised when an issue occurs while connecting to the Modal servers.

## DataLossError


```python
class DataLossError(modal.exception.Error, modal.exception._GRPCErrorWrapper)
```

Raised when data is lost or corrupted.

## DeprecationError


```python
class DeprecationError(UserWarning)
```

UserWarning category emitted when a deprecated Modal feature or API is used.

## DeserializationError


```python
class DeserializationError(modal.exception.Error)
```

Raised to provide more context when an error is encountered during deserialization.

## Error


```python
class Error(Exception)
```

Base class for all Modal errors. See [`modal.exception`](https://modal.com/docs/sdk/py/latest/exception)
for the specialized error classes.

**Usage**

```python notest
import modal

try:
    ...
except modal.Error:
    # Catch any exception raised by Modal's systems.
    print("Responding to error...")
```

## ExecTimeoutError


```python
class ExecTimeoutError(modal.exception.TimeoutError)
```

Raised when a container process exceeds its execution duration limit and times out.

## ExecutionError


```python
class ExecutionError(modal.exception.Error)
```

Raised when something unexpected happened during runtime.

## FilesystemExecutionError


```python
class FilesystemExecutionError(modal.exception.Error)
```

Raised when an unknown error is thrown during a container filesystem operation.

## FunctionTimeoutError


```python
class FunctionTimeoutError(modal.exception.TimeoutError)
```

Raised when a Function exceeds its execution duration limit and times out.

## ImageBuildError


```python
class ImageBuildError(modal.exception.RemoteError)
```

Raised when an Image build fails.

Use the `image_id` attribute to reference the failed Image, e.g. to fetch build logs.

## InputCancellation


```python
class InputCancellation(BaseException)
```

Raised when the current input is cancelled by the task

Intentionally a BaseException instead of an Exception, so it won't get
caught by unspecified user exception clauses that might be used for retries and
other control flow.

## InteractiveTimeoutError


```python
class InteractiveTimeoutError(modal.exception.TimeoutError)
```

Raised when interactive frontends time out while trying to connect to a container.

## InternalError


```python
class InternalError(modal.exception.Error, modal.exception._GRPCErrorWrapper)
```

Raised when an internal error occurs in the Modal system.

## InternalFailure


```python
class InternalFailure(modal.exception.Error)
```

Retriable internal error.

## InvalidError


```python
class InvalidError(modal.exception.Error, modal.exception._GRPCErrorWrapper)
```

Raised when user does something invalid.

## LogsFetchError


```python
class LogsFetchError(modal.exception.Error)
```

Raised when trying to fetch too many logs.

## ModuleNotMountable


```python
class ModuleNotMountable(Exception)
```

## MountUploadTimeoutError


```python
class MountUploadTimeoutError(modal.exception.TimeoutError)
```

Raised when a Mount upload times out.

## NotFoundError


```python
class NotFoundError(modal.exception.Error, modal.exception._GRPCErrorWrapper)
```

Raised when a requested resource was not found.

## OutputExpiredError


```python
class OutputExpiredError(modal.exception.TimeoutError)
```

Raised when the Output exceeds expiration and times out.

## PermissionDeniedError


```python
class PermissionDeniedError(modal.exception.Error, modal.exception._GRPCErrorWrapper)
```

Raised when a user does not have permission to perform the requested operation.

## RemoteError


```python
class RemoteError(modal.exception.Error)
```

Raised when an error occurs on the Modal server.

## RequestSizeError


```python
class RequestSizeError(modal.exception.Error)
```

Raised when an operation produces a gRPC request that is rejected by the server for being too large.

## ResourceExhaustedError


```python
class ResourceExhaustedError(modal.exception.Error, modal.exception._GRPCErrorWrapper)
```

Raised when a server-side resource has been exhausted, e.g. a quota or rate limit.

## SandboxFilesystemDirectoryNotEmptyError


```python
class SandboxFilesystemDirectoryNotEmptyError(modal.exception.SandboxFilesystemError)
```

Raised when a directory is not empty.

## SandboxFilesystemError


```python
class SandboxFilesystemError(modal.exception.Error)
```

Base class for sandbox filesystem errors.

## SandboxFilesystemFileTooLargeError


```python
class SandboxFilesystemFileTooLargeError(modal.exception.SandboxFilesystemError)
```

Raised when a file exceeds the maximum allowed size for a read operation in the sandbox.

## SandboxFilesystemIsADirectoryError


```python
class SandboxFilesystemIsADirectoryError(modal.exception.SandboxFilesystemError)
```

Raised when a file operation in the sandbox targets a directory when it should target a non-directory file.

## SandboxFilesystemNotADirectoryError


```python
class SandboxFilesystemNotADirectoryError(modal.exception.SandboxFilesystemError)
```

Raised when a path component in the sandbox is not a directory.

## SandboxFilesystemNotFoundError


```python
class SandboxFilesystemNotFoundError(modal.exception.SandboxFilesystemError)
```

Raised when a file or directory is not found in the sandbox.

## SandboxFilesystemPathAlreadyExistsError


```python
class SandboxFilesystemPathAlreadyExistsError(modal.exception.SandboxFilesystemError)
```

Raised when a path already exists and the operation requires it to be absent.

## SandboxFilesystemPermissionError


```python
class SandboxFilesystemPermissionError(modal.exception.SandboxFilesystemError)
```

Raised when permission is denied for a file operation in the sandbox.

## SandboxTerminatedError


```python
class SandboxTerminatedError(modal.exception.Error)
```

Raised when a Sandbox is terminated for an internal reason.

## SandboxTimeoutError


```python
class SandboxTimeoutError(modal.exception.TimeoutError)
```

Raised when a Sandbox exceeds its execution duration limit and times out.

## SerializationError


```python
class SerializationError(modal.exception.Error)
```

Raised to provide more context when an error is encountered during serialization.

## ServerWarning


```python
class ServerWarning(UserWarning)
```

Warning originating from the Modal server and re-issued in client code.

## ServiceError


```python
class ServiceError(modal.exception.Error, modal.exception._GRPCErrorWrapper)
```

Raised when an error occurs in basic client/server communication.

## SnapshotCreationError


```python
class SnapshotCreationError(modal.exception.Error)
```

Raised when a Sandbox fails to create an exit snapshot.

## TimeoutError


```python
class TimeoutError(modal.exception.Error)
```

Base class for Modal timeouts.

## UnimplementedError


```python
class UnimplementedError(modal.exception.Error, modal.exception._GRPCErrorWrapper)
```

Raised when a requested operation is not implemented or not supported.

## VersionError


```python
class VersionError(modal.exception.Error)
```

Raised when the current client version of Modal is unsupported.

## VolumeUploadTimeoutError


```python
class VolumeUploadTimeoutError(modal.exception.TimeoutError)
```

Raised when a Volume upload times out.

## WorkspaceManagementError


```python
class WorkspaceManagementError(modal.exception.Error)
```

Raised when an error occurs while managing a workspace.

## simulate_preemption

```python
simulate_preemption(wait_seconds, jitter_seconds=0)
```
Utility for simulating a preemption interrupt after `wait_seconds` seconds.
The first interrupt is the SIGINT signal. After 30 seconds, a second
interrupt will trigger.

This second interrupt simulates SIGKILL, and should not be caught.
Optionally add between zero and `jitter_seconds` seconds of additional waiting before first interrupt.

**Usage**

```python notest
import time
from modal.exception import simulate_preemption

simulate_preemption(3)

try:
    time.sleep(4)
except KeyboardInterrupt:
    print("got preempted") # Handle interrupt
    raise
```

See https://modal.com/docs/guide/preemption for more details on preemption
handling.
