# The xBRL-XML instance document

Everything here is XBRL 2.1, the 2003 Recommendation with errata to 2013-02-20. It is stable and will not change again.

## Contents

- [Namespaces](#namespaces)
- [Document shape](#document-shape)
- [Items: the facts](#items-the-facts)
- [Accuracy: decimals and precision](#accuracy-decimals-and-precision)
- [Contexts](#contexts)
- [Units](#units)
- [Tuples](#tuples)
- [Footnotes](#footnotes)
- [Equality predicates](#equality-predicates)
- [What makes an instance invalid](#what-makes-an-instance-invalid)

## Namespaces

| Prefix | Namespace | What it is |
|---|---|---|
| `xbrli` | `http://www.xbrl.org/2003/instance` | Instance elements: `xbrl`, `context`, `unit`, `item`, `tuple`, `measure` |
| `link` | `http://www.xbrl.org/2003/linkbase` | `schemaRef`, `linkbaseRef`, `roleRef`, `arcroleRef`, `footnoteLink` |
| `xl` | `http://www.xbrl.org/2003/XLink` | XLink element types XBRL derives from |
| `xlink` | `http://www.w3.org/1999/xlink` | `type`, `href`, `role`, `arcrole`, `label`, `from`, `to` |
| `xbrldi` | `http://xbrl.org/2006/xbrldi` | `explicitMember`, `typedMember` |
| `xbrldt` | `http://xbrl.org/2005/xbrldt` | Dimension taxonomy attributes and substitution groups |
| `iso4217` | `http://www.xbrl.org/2003/iso4217` | Currency measures |

The prefixes are conventional; the URIs are normative. Filings bind them however they like, including as the default namespace.

## Document shape

The root is `xbrli:xbrl`, with a strict child order:

```
xbrl
  link:schemaRef      1..n   MUST come first, in document order
  link:linkbaseRef    0..n
  link:roleRef        0..n
  link:arcroleRef     0..n
  ( item | tuple | context | unit | link:footnoteLink )*   any order
```

`@id` (xsd:ID) and `@xml:base` are allowed on the root. Nothing may appear outside the root except comments and processing instructions.

`schemaRef` is a simple XLink (`xlink:type="simple"`, `xlink:href="..."`). At least one is mandatory, and it is the entry point for DTS discovery. `linkbaseRef` in an instance must carry `xlink:arcrole="http://www.w3.org/1999/xlink/properties/linkbase"`.

Note the spec's phrasing: an instance is the `xbrl` *element*, not the file. An instance can in principle be embedded in a larger XML document.

## Items: the facts

An item is any element in the `xbrli:item` substitution group (or a substitution group derived from it). Its content is the value, as text.

```xml
<us-gaap:Assets contextRef="c1" unitRef="usd" decimals="-6" id="f-42">727000000</us-gaap:Assets>
<ci:AccountingPolicy contextRef="c1">Revenue is recognised when...</ci:AccountingPolicy>
<fsa:Employees contextRef="c1" unitRef="pure" decimals="0" xsi:nil="true"/>
```

Rules that matter to a reader:

- `@contextRef` is **required on every item** and must resolve to a `context/@id` in the same instance.
- `@unitRef` is **required on numeric items and forbidden on non-numeric ones**, and must resolve to a `unit/@id`.
- Items **must not nest inside other items**. Structure comes from tuples, not from nesting.
- `@id` (xsd:ID) is optional but common; footnotes point at it.
- Foreign attributes (`##other` namespaces) are allowed on any fact and carry no XBRL meaning. iXBRL relies on this.
- `xsi:type` **must not** appear on items or tuples. Types come from the taxonomy.

**Numeric** means the type derives from `xsd:decimal`, `xsd:float`, or `xsd:double`, or from `xbrli:fractionItemType`. Note that dates are *not* numeric. You cannot tell numeric from non-numeric without the taxonomy — but you can infer it from the presence of `unitRef`, which is what instance-only readers do.

`xsi:nil="true"` means the value is absent, not zero. A nil fact has empty content and must not carry `decimals` or `precision`.

## Accuracy: decimals and precision

A non-nil numeric item carries **exactly one** of `@decimals` or `@precision`. Never both, never neither. Fraction-typed items carry neither.

- `@decimals` — an integer or `INF`. "Correct to n decimal places." Negative values are normal and common: `decimals="-3"` means correct to the nearest thousand.
- `@precision` — a non-negative integer or `INF`. "Correct to n significant figures."
- `INF` in either means the lexical value is exact.
- `precision="0"` means **nothing is known** about the value. Every value-equality comparison involving it is false, and any calculation it participates in is inconsistent.

These describe *the accuracy of the source*, answering "what range of real values could have produced this figure?" — not "what should I do to this number?". A fact with `precision="1"` and value `99` asserts the real value was in `[85, 95)`, which is outside the reported value. That is intended, if counter-intuitive.

They are also not scale. The value in the instance is always at full magnitude.

### Inferring decimals from precision

If you need a single accuracy model, convert `precision` to `decimals`:

- `precision="INF"` → `decimals = INF`.
- Value is numerically zero → `decimals = INF` (zero is treated as a singularity of infinite accuracy).
- `precision="0"` → nothing can be inferred; comparisons fail and calculations are inconsistent.
- Otherwise → `decimals = precision - floor(log10(abs(value))) - 1`.

Fraction-typed items are treated as `INF` if used in calculations.

The reverse direction is the same formula rearranged: `precision = decimals + floor(log10(abs(value))) + 1`, floored at 0. Note that the leading-digit term is negative for values below 1, so `0.001e-3` with `decimals="4"` yields `precision="0"` — nothing known. The spec's worked table is in §4.6.6.

## Contexts

```xml
<xbrli:context id="D2025">
  <xbrli:entity>
    <xbrli:identifier scheme="http://www.dcca.dk/cvr">12345678</xbrli:identifier>
    <xbrli:segment>…optional…</xbrli:segment>
  </xbrli:entity>
  <xbrli:period>…</xbrli:period>
  <xbrli:scenario>…optional…</xbrli:scenario>
</xbrli:context>
```

Order is fixed: `entity`, `period`, then optional `scenario`. `segment` is inside `entity`. `@id` is required and is an xsd:ID, so it may not start with a digit.

### Entity

`identifier` has a required `@scheme` (a URI naming the identification authority) and a token body. XBRL International is not an authority and makes no promise the identifier resolves. Real schemes:

| Scheme URI | Identifier |
|---|---|
| `http://www.sec.gov/CIK` | 10-digit SEC CIK, zero padded |
| `http://standards.iso.org/iso/17442` | 20-character LEI (what ESEF prescribes) |
| `http://www.dcca.dk/cvr` | Danish CVR number |

### Period

Exactly one of three shapes:

```xml
<xbrli:period><xbrli:instant>2025-12-31</xbrli:instant></xbrli:period>
<xbrli:period><xbrli:startDate>2025-01-01</xbrli:startDate><xbrli:endDate>2025-12-31</xbrli:endDate></xbrli:period>
<xbrli:period><xbrli:forever/></xbrli:period>
```

Each date is `xsd:date` or `xsd:dateTime` (the union `xbrli:dateUnion`).

**The date normalisation rule, which everyone gets wrong once:**

- A bare date in `startDate` means `T00:00:00` on that day — midnight at the *start*.
- A bare date in `endDate` or `instant` means that day **plus one day** at `T00:00:00` — midnight at the *end*.

So `<instant>2025-12-31</instant>` is the same moment as `<instant>2026-01-01T00:00:00</instant>`. The reason is that XML Schema forbids hour 24. `endDate` must be strictly after `startDate` once normalised.

The taxonomy's `periodType` on a concept constrains which shape is legal: `instant` concepts require `instant`; `duration` concepts require `startDate`/`endDate` or `forever`.

### Segment and scenario

Both are optional free-form containers. Contents must not be in the instance namespace or in a substitution group headed by an instance element. In practice, since Dimensions 1.0, they hold `xbrldi:explicitMember` and `xbrldi:typedMember` and nothing else — but the base spec permits arbitrary XML, and pre-dimensional filings use it. See [`dimensions.md`](dimensions.md).

Neither may be empty if present.

## Units

```xml
<xbrli:unit id="usd"><xbrli:measure>iso4217:USD</xbrli:measure></xbrli:unit>
<xbrli:unit id="shares"><xbrli:measure>xbrli:shares</xbrli:measure></xbrli:unit>
<xbrli:unit id="pure"><xbrli:measure>xbrli:pure</xbrli:measure></xbrli:unit>
<xbrli:unit id="usdPerShare">
  <xbrli:divide>
    <xbrli:unitNumerator><xbrli:measure>iso4217:USD</xbrli:measure></xbrli:unitNumerator>
    <xbrli:unitDenominator><xbrli:measure>xbrli:shares</xbrli:measure></xbrli:unitDenominator>
  </xbrli:divide>
</xbrli:unit>
```

A unit contains **either** one or more `measure` elements (implicitly multiplied) **or** exactly one `divide`. `@id` is required.

`measure` content is an `xsd:QName` — a QName in element content, so **you must resolve the prefix yourself**.

Type constraints:

| Item type | Unit must be |
|---|---|
| `monetaryItemType` and derivatives | a single measure whose local name is an ISO 4217 code valid during the fact's period, in namespace `http://www.xbrl.org/2003/iso4217` |
| `sharesItemType` and derivatives | a single measure `xbrli:shares` |
| rates, percentages, ratios | a single measure `xbrli:pure`, with the value as a decimal — **not** multiplied by 100 |

A measure in the instance namespace must be `pure` or `shares`; nothing else. Units must be in simplest form: no measure may appear in both numerator and denominator of a `divide`.

The **Units Registry (UTR)** adds a registry of non-monetary units (mass, energy, area, per-share monetary types, and so on) tied to DTR data types. Filing programmes may require UTR validation; it is optional in the base spec.

## Tuples

A tuple is a compound fact: a group of items that only make sense together, such as a director's name, title, and age.

```xml
<my:ManagementInformation>
  <my:ManagementName contextRef="c1">Jane Doe</my:ManagementName>
  <my:ManagementTitle contextRef="c1">CFO</my:ManagementTitle>
</my:ManagementInformation>
```

Rules: tuples take no `contextRef`, no `unitRef`, no `periodType`, no `balance`. Children must be items or tuples. Content is never mixed or simple.

**Tuples are legacy.** The OIM does not support them at all — a report containing tuples cannot be represented in xBRL-JSON or xBRL-CSV, and Calculations 1.1 downgrades to a warning and processes as if they were absent. Modern taxonomies use dimensions instead. You will still meet them in older filings and in XBRL GL.

If you are writing an instance-only reader and do not need tuples, refusing them explicitly is better than flattening them: a flattened tuple loses the grouping that was its entire purpose.

## Footnotes

Irregular associations between facts and prose, expressed as an XLink extended link inside the instance:

```xml
<link:footnoteLink xlink:type="extended"
                   xlink:role="http://www.xbrl.org/2003/role/link">
  <link:loc xlink:type="locator" xlink:href="#f-42" xlink:label="fact"/>
  <link:footnote xlink:type="resource" xlink:label="fn" xml:lang="en"
                 xlink:role="http://www.xbrl.org/2003/role/footnote">
    Including the effects of the merger.
  </link:footnote>
  <link:footnoteArc xlink:type="arc" xlink:from="fact" xlink:to="fn"
                    xlink:arcrole="http://www.xbrl.org/2003/arcrole/fact-footnote"/>
</link:footnoteLink>
```

`link:footnote` content may be mixed text and XHTML. `@xml:lang` is **required** on every footnote. The standard arcrole is `fact-footnote`; `http://www.xbrl.org/2009/arcrole/fact-explanatoryFact` (from the LRR) links a fact to another fact that explains it.

Locators point at facts by `@id`, which is why taxonomy authors are told not to prohibit `@id` on items and tuples.

## Equality predicates

XBRL 2.1 defines a family of equality relations. They are dry but they are exactly what you implement when you deduplicate or compare.

| Predicate | Means |
|---|---|
| **x-equal** | XPath `=` returns true |
| **s-equal** | *structure-equal*: equal in the XML value space, or all XBRL-relevant sub-elements and attributes are s-equal. This is how contexts and units are compared. |
| **c-equal** | *context-equal*: items of the same type whose contexts are s-equal |
| **u-equal** | *unit-equal*: same units of measurement |
| **p-equal** | *parent-equal*: same parent element (matters only inside tuples) |
| **v-equal** | *value-equal*: c-equal items with the same non-numeric value, or numeric values equal within the tolerance given by the lesser of their accuracies |

**Duplicate items** are two items of the same concept, in the same context, under the same parent. Note that this is defined by *string* comparison of the context contents, which is why QNames written with different prefixes for the same namespace compare unequal under the 2.1 rules. The OIM replaces this with a proper model-based comparison — prefer the OIM definitions. See [`oim.md`](oim.md).

## What makes an instance invalid

Useful shortlist for a reader that wants to fail loudly rather than produce quiet nonsense:

- A fact whose `contextRef` or `unitRef` names something the document never defines.
- A numeric fact with no `unitRef`, or a non-numeric fact with one.
- A non-nil numeric fact with both `decimals` and `precision`, or with neither.
- Duplicate `@id` on contexts or units; missing `@id` on either.
- A context whose period is none of instant, duration, or forever; an `endDate` not after its `startDate`.
- An empty `segment` or `scenario`.
- A `divide` sharing a measure between numerator and denominator.
- Content outside the root element.
- An item nested inside another item.
- `xsi:type` on a fact.

A fact whose context is missing is not a fact you can drop — it is a number with nothing to say what it is a number of. Failing the parse is the correct response.
