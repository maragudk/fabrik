# Inline XBRL

iXBRL is what regulators actually mandate now: one XHTML document that a human reads in a browser and a machine reads as XBRL. This is the format most filings arrive in.

## Contents

- [The model](#the-model)
- [Namespaces and versions](#namespaces-and-versions)
- [Document structure](#document-structure)
- [The elements](#the-elements)
- [Extraction algorithm](#extraction-algorithm)
- [Transformations](#transformations)
- [Duplicates](#duplicates)
- [Pitfalls](#pitfalls)

## The model

An **Inline XBRL Document Set (IXDS)** is one or more XHTML documents. Processing it produces one or more **target documents**, each a complete, XBRL-2.1-valid instance. That instance is the thing with facts in it; the XHTML is a rendering.

Two consequences worth internalising:

1. An iXBRL file is not an instance. Handing it to an instance parser yields zero facts, not an error. Detect and reject.
2. A single iXBRL document can define several target documents, selected by `@target` on the ix elements. Facts with no `@target` go to the *default* target document. Most filings use only the default, but a filing carrying, say, both consolidated and parent-only figures may not.

A **document set** may span several files. The Report Packages spec is the standard way to bundle them; see [`programmes.md`](programmes.md).

## Namespaces and versions

| Prefix | Namespace | Version |
|---|---|---|
| `ix` | `http://www.xbrl.org/2013/inlineXBRL` | **1.1** — current |
| `ix` | `http://www.xbrl.org/2008/inlineXBRL` | 1.0 — older, still encountered |
| `ixt` | `http://www.xbrl.org/inlineXBRL/transformation/YYYY-MM-DD` | transformation registry, version by date |

Registry namespaces, oldest to newest: `2010-04-20` (TRR1), `2011-07-31` (TRR2), `2015-02-26` (TRR3), `2020-02-12` (TRR4), `2022-02-16` (TRR5). TRR6 is a working draft. A single filing may bind more than one — the `format` QName's namespace selects the registry per fact, so resolve it per use, not per document.

`xbrli`, `link`, `xlink`, `xbrldi` are as in an ordinary instance and appear verbatim in the header.

## Document structure

```xml
<html xmlns="http://www.w3.org/1999/xhtml"
      xmlns:ix="http://www.xbrl.org/2013/inlineXBRL"
      xmlns:xbrli="http://www.xbrl.org/2003/instance"
      xmlns:ixt="http://www.xbrl.org/inlineXBRL/transformation/2022-02-16"
      xmlns:iso4217="http://www.xbrl.org/2003/iso4217"
      xmlns:fsa="http://xbrl.dcca.dk/fsa">
  <body>
    <div style="display:none">
      <ix:header>
        <ix:hidden>
          <ix:nonNumeric name="fsa:LegalForm" contextRef="c1">A/S</ix:nonNumeric>
        </ix:hidden>
        <ix:references>
          <link:schemaRef xlink:type="simple" xlink:href="https://…/entry.xsd"/>
        </ix:references>
        <ix:resources>
          <xbrli:context id="c1">…</xbrli:context>
          <xbrli:unit id="DKK"><xbrli:measure>iso4217:DKK</xbrli:measure></xbrli:unit>
        </ix:resources>
      </ix:header>
    </div>

    <p>Revenue for the year was
      <ix:nonFraction name="fsa:Revenue" contextRef="c1" unitRef="DKK"
                      decimals="-3" scale="3" format="ixt:num-dot-decimal"
                      id="f1">12,450</ix:nonFraction> thousand.</p>
  </body>
</html>
```

`ix:header` holds everything not displayed. Its content model is strictly `(ix:hidden?, ix:references*, ix:resources?)`. There must be at least one `ix:header` in the document set, it must not be inside HTML `<head>`, and it must be wrapped so browsers do not render it — `display:none` on an ancestor `div` is the recommended idiom, and processors may warn if it is missing.

`ix:resources` is where the `xbrli:context` and `xbrli:unit` elements live, verbatim, exactly as they would appear in an instance. `ix:references` holds the `link:schemaRef` and `link:linkbaseRef` elements — at least one `ix:references` per target document.

`ix:hidden` holds facts that must be reported but must not be displayed. It must be a direct child of `ix:header`.

## The elements

| Element | Represents |
|---|---|
| `ix:nonFraction` | a numeric fact (non-fraction) |
| `ix:nonNumeric` | a non-numeric fact |
| `ix:fraction` / `ix:numerator` / `ix:denominator` | a fraction-typed fact |
| `ix:tuple` | a tuple |
| `ix:footnote` | a `link:footnote` resource |
| `ix:relationship` | a footnote arc, by `fromRefs`/`toRefs` |
| `ix:references` | `schemaRef` / `linkbaseRef` container |
| `ix:resources` | contexts, units, and other non-displayed instance content |
| `ix:header` | the container for the three above |
| `ix:hidden` | non-displayed facts |
| `ix:continuation` | additional content for a `nonNumeric` or `footnote` |
| `ix:exclude` | content to omit from the enclosing fact's value |

Attributes defined by the spec: `arcrole`, `contextRef`, `continuedAt`, `decimals`, `escape`, `footnoteRole`, `format`, `fromRefs`, `id`, `linkRole`, `name`, `precision`, `order`, `scale`, `sign`, `target`, `title`, `toRefs`, `tupleID`, `tupleRef`, `unitRef`.

### ix:nonFraction

```
<ix:nonFraction name=QName contextRef=NCName unitRef=NCName
                (decimals|precision) [format=QName] [scale=integer] [sign="-"]
                [id] [target] [order] [tupleRef] [any foreign attribute]>
  content: one ix:nonFraction, or one text node
</ix:nonFraction>
```

- `name`, `contextRef`, `unitRef` are required.
- Exactly one of `decimals` or `precision`, unless `xsi:nil="true"`.
- `sign`, if present, must be exactly `"-"`.
- Exactly one child: a text node, or a nested `ix:nonFraction` (used to tag the same displayed number as two facts). A nested one must agree on `format`, `scale`, and `unitRef`.
- Foreign attributes are copied through to the target document. Attributes in the instance namespace are forbidden.

### ix:nonNumeric

```
<ix:nonNumeric name=QName contextRef=NCName
               [format] [escape=boolean] [continuedAt=NCName]
               [id] [target] [order] [tupleRef]>
  content: any elements and text
</ix:nonNumeric>
```

The value is either the concatenation of all descendant text nodes (default), or — when `escape="true"` — the *escaped serialisation* of the marked-up content. `escape="true"` is how text blocks preserve their HTML: the resulting fact value is a string containing HTML markup. Relative URLs inside are resolved first.

`ix:exclude` removes a subtree from the value (page headers crossing a page break, for example) without preventing its own descendants from being processed as facts in their own right.

### ix:continuation

Splits one fact's text across non-contiguous parts of the document — necessary when a note spans pages and closing tags mid-paragraph would break well-formedness.

```xml
<ix:nonNumeric name="ifrs-full:DisclosureOfX" contextRef="c1"
               escape="true" continuedAt="c-1">first part</ix:nonNumeric>
…
<ix:continuation id="c-1" continuedAt="c-2">second part</ix:continuation>
…
<ix:continuation id="c-2">third part</ix:continuation>
```

The chain is followed by matching `continuedAt` to `id`. `ix:continuation` requires `@id`, must **not** be inside `ix:hidden`, each id must be referenced exactly once, and no element in a chain may be a descendant of another element in the same chain.

### ix:footnote and ix:relationship

`ix:footnote` needs `@id` and an in-scope `xml:lang`. Its role defaults to `http://www.xbrl.org/2003/role/footnote`. It supports `continuedAt` and `ix:exclude` the same way `nonNumeric` does.

`ix:relationship` ties facts to footnotes:

```xml
<ix:relationship arcrole="http://www.xbrl.org/2003/arcrole/fact-footnote"
                 fromRefs="f1 f2" toRefs="fn1"/>
```

`fromRefs`/`toRefs` are space-separated id lists. `arcrole` defaults to `fact-footnote`, `linkRole` to `http://www.xbrl.org/2003/role/link`.

### ix:tuple

Membership works two ways at once, because HTML nesting rarely matches tuple structure. A tuple's content is both its fact descendants that carry no `tupleRef` (stopping at any intervening `ix` element), *and* any element anywhere in the document set whose `tupleRef` matches this tuple's `tupleID`. Every member — and only a member — must carry `@order`; members sharing an order must have the same normalised value. `tupleID` must be unique across the document set, and a tuple may not end up inside its own content. Rare; treat as legacy.

## Extraction algorithm

For each target document:

1. Collect every `ix:references` with that target; their `schemaRef`/`linkbaseRef` children become the instance's references. Namespace declarations in scope on `ix:references` must be consistent across the set for a given target.
2. Copy every `xbrli:context` and `xbrli:unit` from `ix:resources` verbatim.
3. For each `ix:nonFraction`, `ix:nonNumeric`, `ix:fraction`, `ix:tuple` with that target, emit an element whose type is the resolved `@name` QName, carrying `contextRef`, `unitRef`, `decimals`/`precision`, `id`, and any foreign attributes.
4. Compute the value.
5. Build `link:footnoteLink` from `ix:footnote` and `ix:relationship`.

**Value computation for `ix:nonFraction`, in order:**

```
raw   = text content (or the nested ix:nonFraction's value)
v     = format ? applyTransform(format, raw) : raw
v     = v × 10^scale          (if scale present)
v     = -v                    (if sign="-")
```

If `format` is absent, the raw text must already be a valid non-negative number — negatives are always expressed with `@sign`, never a leading minus in the display text.

**Value computation for `ix:nonNumeric`:** walk the continuation chain, concatenate content, drop everything under any `ix:exclude`, replace any nested ix element with its own children, then either serialise (if `escape="true"`) or concatenate text nodes. Apply `format` if present.

The result must be XBRL-valid against the target document's DTS — the two escape hatches are "there is a transformation that produces a valid value" and "the raw text is already valid".

## Transformations

`@format` is a QName naming a rule in a Transformation Rules Registry, resolved via the QName's namespace. The rule converts human formatting into a valid XML Schema lexical value.

The registries are dominated by date parsing, because dates are written differently in every language. TRR5 covers roughly 100 rules. Shapes:

- `ixt:date-day-monthname-year-da`, `…-de`, `…-en`, `…-fr`, … — one per language, plus year/month and month/day variants, plus Roman numeral months, Japanese eras, and the Indian National Calendar.
- `ixt:num-dot-decimal` — `1,234,567.89` → `1234567.89`
- `ixt:num-comma-decimal` — `1.234.567,89` → `1234567.89`
- `ixt:num-unit-decimal` — numbers written with unit words, e.g. `1 234 kr 56 øre`
- `…-apos` variants — the same, allowing `'` as a thousands separator (Swiss style)
- `ixt:fixed-empty`, `ixt:fixed-false`, `ixt:fixed-true`, `ixt:fixed-zero` — ignore the input, emit a constant

Numeric transform outputs are normalised to a non-negative decimal; the sign comes from `@sign`.

Practical note: if you support only the numeric transforms plus a handful of date formats for your target jurisdictions, you cover the overwhelming majority of real filings. Full registry support is a large but mechanical job, and the registry XML files are machine-readable if you want to generate it.

## Duplicates

The specification **permits but does not require** a processor to de-duplicate complete duplicates when producing the target document. Consequences:

- The same iXBRL file processed by two conforming tools can yield different fact counts.
- The presence of `@id` on facts effectively prevents de-duplication, because a distinct fact must be created per distinct id.
- Consistent duplicates (same fact, different precision) and inconsistent duplicates are **never** de-duplicated.

Good tagging practice is to tag every visible occurrence of a figure, so duplicates are the normal case, not an error. The recommended handling is: require `@id` on all facts, reject inconsistent duplicates, de-duplicate complete duplicates, and keep only the most precise of a set of consistent duplicates. See [`oim.md`](oim.md) for the definitions.

## Pitfalls

**No DOCTYPE.** A DOCTYPE triggers DTD resolution that will fail. iXBRL has no normative DTD.

**Declare XHTML on the root only.** Namespace declarations elsewhere have undefined treatment across browsers.

**Prefix scope for `@name`.** The `name` attribute is a QName in an attribute value; the prefix must be in scope *at that element*. A document that binds `fsa:` on a `<div>` halfway down is legal and your resolver has to cope.

**`xml:base` and relative URLs.** `schemaRef` hrefs are frequently relative. Resolve against `xml:base` and the document URL. Filings without a predetermined location are a known problem area.

**Hidden facts are still facts.** Anything in `ix:hidden` is part of the target document. Skipping the header loses required identifying facts.

**`escape="true"` values contain HTML.** Store them as strings; do not try to normalise the markup. Two serialisations of the same fragment are equal as XHTML but unequal as strings, which the OIM explicitly calls out.

**Scale and decimals are independent.** `scale="3" decimals="-3"` is a normal combination: displayed in thousands, reported to the nearest thousand. Applying scale twice, or treating `decimals` as scale, are the two classic bugs.

**Multiple `xml:lang` across a document set.** Different documents in one IXDS may use different languages, and a fact's language is inherited from its nearest ancestor with `xml:lang`.

**Validation levels.** A *Conformant Processor* transforms anything; a *Validating Conformant Processor* accepts only XHTML-rooted document sets conforming to the XHTML+iXBRL schema and rejects everything else. Know which you are building.
