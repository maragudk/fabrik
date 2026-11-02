# Search syntax

Some search boxes in Modal accept a small query language, so you can filter by
field instead of scanning raw output.

## Filters

A query is a list of filters separated by spaces. A filter is either a
`key:value` pair or text to search for. Every filter has to match: they're
combined implicitly with AND, never OR.

`key:value` matches items whose `key` is `value` — e.g. `status:success`.

* **Negation** — put `-` in front of a filter to exclude what it matches:
  `-status:success`.
* **Multiple values** — group them with `OR` inside parentheses:
  `status:(success OR failure)`. The group belongs to one key, and `OR` has to
  be capitalized.

## Searching free text

Some search boxes also accept free text filters (any filter without a key/`:`
is free text). For example, `timeout` searches for that word, and `-timeout`
excludes it. You may query for free text without quotes, unless a special
character is used.

## Quoting

Wrap a filter in double quotes to search for exactly what is inside them.
Quote a filter that contains a space, a parenthesis, a quote, a backslash, or
a `:` you mean literally:

* `name:"my app"` — a value with a space in it.
* `"status: success"` — the text `status: success`, not a `key:value` filter.

## Escapes

A backslash only escapes a quote or another backslash, and only inside quotes.
Anywhere else — outside quotes, before any other character, or trailing at the
end of a quoted string — it's highlighted as an error:

* `"a \"quoted\" word"` — text holding double quotes.
* `"C:\\dir"` — text holding a backslash.

## Examples

| Query                         | Matches                                                                     |
| ----------------------------- | --------------------------------------------------------------------------- |
| `status:success`              | Items whose status is success.                                              |
| `-status:success`             | Everything whose status is not success.                                     |
| `status:(success OR failure)` | Items whose status is either one.                                           |
| `status:success timeout`      | Items whose status is success AND that match the text `timeout`.            |
| `name:"my app"`               | Items named exactly `my app`.                                               |
| `timeout`                     | Items matching the text `timeout`.                                          |
| `-timeout`                    | Items not matching the text `timeout`.                                      |
| `-"connection timeout"`       | Items not matching the text `connection timeout`.                           |
| `"-timeout"`                  | Items matching the text `-timeout`, which is not negated.                   |
| `"status: success"`           | Items matching the text `status: success`, since quoting forces text.       |
| `foo:bar`                     | Items matching the text `foo:bar`, highlighted because `foo` isn't a field. |
| `"C:\dir"`                    | An error — `\d` doesn't escape anything.                                    |
| `"C:\\dir"`                   | Items matching the text `C:\dir`.                                           |
