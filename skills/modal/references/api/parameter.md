# parameter

```python
parameter(*, default=_no_default, init=True)
```
Used to specify options for modal.cls parameters, similar to dataclass.field for dataclasses
```
class A:
    a: str = modal.parameter()

```

If `init=False` is specified, the field is not considered a parameter for the
Modal class and not used in the synthesized constructor. This can be used to
optionally annotate the type of a field that's used internally, for example values
being set by @enter lifecycle methods, without breaking type checkers, but it has
no runtime effect on the class.
