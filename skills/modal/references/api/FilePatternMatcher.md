# FilePatternMatcher


```python
class FilePatternMatcher(modal.file_pattern_matcher._AbstractPatternMatcher)
```

Allows matching file Path objects against a list of patterns.

**Usage**

```python
from pathlib import Path
from modal import FilePatternMatcher

matcher = FilePatternMatcher("*.py")

assert matcher(Path("foo.py"))

# You can also negate the matcher.
negated_matcher = ~matcher

assert not negated_matcher(Path("foo.py"))
```

```python
__init__(self, *pattern)
```
Initialize a new FilePatternMatcher instance.

**Parameters**

<Parameter name="*pattern" type="str" description="One or more pattern strings." />

**Raises**

- `ValueError`: If an illegal exclusion pattern is provided.

## can_prune_directories

```python
can_prune_directories(self)
```
Returns True if this pattern matcher allows safe early directory pruning.

Directory pruning is safe when matching directories can be skipped entirely
without missing any files that should be included. This is for example not
safe when we have inverted/negated ignore patterns (e.g. "!**/*.py").

## from_file

```python
from_file(cls, file_path)
```
Initialize a new FilePatternMatcher instance from a file.

The patterns in the file will be read lazily when the matcher is first used.

**Parameters**

<Parameter name="file_path" type="Path" description="The path to the file containing patterns." />

**Usage**

```python
from modal import FilePatternMatcher

matcher = FilePatternMatcher.from_file("/path/to/ignorefile")
```
