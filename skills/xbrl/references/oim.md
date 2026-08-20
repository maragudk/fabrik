# The Open Information Model, xBRL-JSON, and xBRL-CSV

The OIM is XBRL International's attempt to say what an XBRL report *means*, independently of how it is written down. It is the most useful thing to read if you are designing an internal data model, even if every byte you ever touch is XML.

## Contents

- [What the OIM is for](#what-the-oim-is-for)
- [The report model](#the-report-model)
- [Core dimensions](#core-dimensions)
- [Links and footnotes](#links-and-footnotes)
- [Equality and equivalence](#equality-and-equivalence)
- [Duplicates and alternatives](#duplicates-and-alternatives)
- [xBRL-JSON](#xbrl-json)
- [xBRL-CSV](#xbrl-csv)
- [What the OIM does not cover](#what-the-oim-does-not-cover)

## What the OIM is for

XBRL 2.1's XML has a lot of detail that carries no meaning: which context id was used, whether a dimension went in `segment` or `scenario`, whether a value was written `1.0` or `1.00`, whether `precision` or `decimals` was used. Working with the data in JSON, CSV, or a database meant every implementer decided independently what was significant. The OIM settles it.

Three specs share the model: **xBRL-XML** (the mapping to and from XBRL 2.1 syntax), **xBRL-JSON**, and **xBRL-CSV**. All are Recommendations from 2021 with errata to 2023-04-19.

Supported input: XBRL 2.1, Dimensions 1.0, Extensible Enumerations 2.0. **Tuples are not supported** — a report containing them cannot be modelled.

## The report model

```
Report
  {taxonomy}   list of schema URLs, non-empty
  {facts}      set of Facts
  {base-url}   optional absolute URL

Fact
  {id}         NCName, required, unique in the report
  {dimensions} set of Dimensions
  {value}      the value, or nil
  {decimals}   integer or "infinity"; present only on non-nil numeric facts
  {links}      set of link groups
```

Note what is *absent*: no contexts, no units as objects, no lexical representations, no `precision`. Contexts and units dissolve into dimensions. `precision` is converted to `decimals` on the way in. `1`, `1.0`, and `1.00` are the same value.

`{id}` is mandatory and unique. When a model is built from a source that lacks ids, they are generated. Ids give duplicate facts distinct identity and provide traceability back to a position in an iXBRL document — but they carry no semantics, and equivalence ignores them.

Fact classification, which drives which dimensions may appear:

- **numeric fact** — datatype derived from `xs:decimal`, `xs:double`, or `xs:float`
- **text fact** — derived from `xs:string`, but **not** `xs:language`, `xs:Name`, `dtr-type:domainItemType`, `dtr-type:noLangTokenItemType`, or `dtr-type:noLangStringItemType`
- **enumeration fact** — a concept typed by Extensible Enumerations; the value is one expanded name or a set of them

## Core dimensions

| Dimension | Key | Value | Optional? |
|---|---|---|---|
| Concept | `xbrl:concept` | an expanded name | **required on every fact** |
| Entity | `xbrl:entity` | `{scheme}` URI + `{identifier}` string | optional |
| Period | `xbrl:period` | an ISO 8601 time interval | optional for duration; required for instant |
| Unit | `xbrl:unit` | `{numerators}` and optional `{denominators}`, both unordered collections of expanded names | only on numeric facts, and optional there |
| Language | `xbrl:language` | a BCP 47 code | only on text facts, and optional there |
| Note id | `xbrl:noteId` | equals the fact's `{id}` | only on `xbrl:note` facts |

Plus any number of **taxonomy-defined dimensions**, keyed by expanded name, with a QName value (explicit) or a typed value (typed). Namespace `https://xbrl.org/2021` for the core dimension names.

The mappings that surprise people:

- **Instants are zero-length intervals.** There is one period model, not two. An instant is `2025-01-01T00:00:00/2025-01-01T00:00:00`, and the XML `endDate`/`instant` end-of-day normalisation is applied on the way in.
- **`forever` is the absence of the period dimension.** Not a special value.
- **`xbrli:pure` is the absence of the unit dimension.** A unit with a single `pure` numerator and no denominator is explicitly illegal in the model (`oime:illegalPureUnit`).
- **The absence of an entity is representable.** In XML it is spelled with the reserved scheme `https://xbrl.org/2021/entities` and identifier `NA`; that combination is illegal as a real entity.
- **Dimension defaults are never in the model.** A fact relying on a default carries no value for that dimension. Applications may infer it when validating against a hypercube, but the model does not store it.
- **Units are unordered collections.** `USD × shares` equals `shares × USD`.
- **Language codes are compared lowercased** after whitespace normalisation, because BCP 47 is case-insensitive but XML Schema's canonical form does not specify a case.

Typed dimensions are restricted: no complex types, no `xs:ID`/`IDREF`/`ENTITY`/`NMTOKEN`/`NOTATION` families, no list or union types except `xbrli:dateUnion` and restrictions of it.

## Links and footnotes

Footnotes generalise into **link groups**. Each is attached to a source fact and has:

- `{group}` — a URI, corresponding to the extended link role
- `{link type}` — a URI, corresponding to the arcrole
- `{target facts}` — an ordered list of facts

The footnote *text* becomes a fact in its own right, on the reserved concept `xbrl:note`. For the standard link type `http://www.xbrl.org/2003/arcrole/fact-footnote`, every target must be an `xbrl:note` fact. Because several notes in one report would otherwise be duplicates of each other, `xbrl:note` facts carry the `xbrl:noteId` core dimension, set equal to their own id.

## Equality and equivalence

Two levels, and the distinction matters:

- **Equal** — every property matches, including `{id}`.
- **Equivalent** — every property matches except `{id}` and `noteId`, which are ignored. Equivalent reports convey the same information and need not have the same number of facts.

Value equality is by datatype: same set of expanded names for enumerations; prefix-resolved comparison for prefixed content; lowercased comparison for language values; otherwise same value-space value. Relative `anyURI` values are compared **as written**, without absolutisation.

`xbrl:note` values are serialised XHTML compared as strings, which the spec notes is imperfect — reordering attributes produces unequal values for equivalent markup. This only bites data derived from XML.

## Duplicates and alternatives

This is the section to read before designing storage.

**Duplicate facts**: two facts with exactly the same set of dimensions and the same dimension values. Legal under the model. Classes:

| Class | Definition |
|---|---|
| **Complete duplicates** | value-equal, and same `{decimals}` (or absent on both) |
| **Consistent duplicates** | complete duplicates, or numeric facts whose intervals all overlap |
| **Inconsistent duplicates** | duplicates that are neither |

Numeric consistency uses closed intervals: a fact with value `v` and `{decimals}` `N` represents `[v − 0.5×10^−N, v + 0.5×10^−N]`, or a point for infinity. All intervals in the set must pairwise overlap. Facts with the *same* decimals must have the same value.

```
A: 2,500 (decimals = -2)  => [2450, 2550]
B: 2,000 (decimals = -3)  => [1500, 2500]
C: 2,470 (decimals = -1)  => [2465, 2475]
```

All overlap, so all three are consistent with a single actual value in `[2465, 2475]`. Note that consistency is **not transitive** — A consistent with B and with C does not make B consistent with C.

**Alternatives** are dimensionally *distinct* but usually undesirable:

- **Multi-language alternatives** — text facts identical except for the language dimension.
- **Multi-unit alternatives** — numeric facts identical except for the unit dimension.

None of these are errors in the model. Downstream specs and filing rules decide. Standard codes if you want them: `oime:disallowedDuplicateFacts`, `oime:illegalMultiLanguageAlternatives`, `oime:illegalMultiUnitAlternatives`.

**Recommended policy** (from the Handling Duplicate Facts working group note):

- Require `@id` on all facts in iXBRL.
- Reject inconsistent duplicates.
- De-duplicate complete duplicates.
- Of a set of consistent duplicates, keep the most precise.
- Decide explicitly whether multi-language alternatives are allowed; if so, document how.
- Use Calculations 1.1 semantics for calculation checks.

Storage consequence: once inconsistent duplicates are rejected and complete duplicates removed, a fact is uniquely identified by `(dimensions, decimals)`. Before that cleanup, dimensions alone are not a key. If you need traceability back to positions in an iXBRL document, keep the complete duplicates and key on `{id}`.

## xBRL-JSON

A whole report as one JSON object. Identified by `/documentInfo/documentType` = `https://xbrl.org/2021/xbrl-json`. UTF-8, unique keys required.

```json
{
  "documentInfo": {
    "documentType": "https://xbrl.org/2021/xbrl-json",
    "namespaces": {
      "tax": "http://example.com/taxonomy",
      "iso4217": "http://www.xbrl.org/2003/iso4217",
      "cid": "http://www.sec.gov/CIK"
    },
    "taxonomy": ["https://example.com/taxonomy/entry.xsd"]
  },
  "facts": {
    "f923": {
      "value": "1234",
      "decimals": 0,
      "dimensions": {
        "concept": "tax:Revenue",
        "entity": "cid:0000320193",
        "period": "2025-01-01T00:00:00/2026-01-01T00:00:00",
        "unit": "iso4217:USD",
        "tax:RegionDimension": "tax:Europe"
      }
    }
  }
}
```

Points of note:

- `facts` is an **object keyed by fact id**, not an array.
- Values are always strings (or `null` for nil), in a lexical form valid for the datatype. Numbers are not JSON numbers — that avoids float round-tripping.
- The entity is an **SQName**: a prefix bound to the scheme URI, colon, the identifier.
- Periods are ISO 8601 intervals; instants are a single timestamp.
- Units are the "unit string representation": `iso4217:USD/xbrli:shares` for per-share, `*` for multiplication.
- `language` must be lowercase.
- Taxonomy-defined dimension keys are prefixed QNames and the prefix must not be `xbrl`.
- Extra properties are allowed on `Report`, `Fact`, and `documentInfo` only, must be QNames, and must not use an `xbrl.org` namespace.
- `linkTypes` and `linkGroups` are URI-alias maps; reserved aliases are `footnote`, `explanatoryFact`, and `_` (for `http://www.xbrl.org/2003/role/link`).

xBRL-JSON is a pleasant target format. Very little is published in it — but Arelle will convert an instance or iXBRL document to it, which makes it an excellent internal representation.

## xBRL-CSV

A JSON metadata file plus zero or more CSV data tables. Identified by documentType `https://xbrl.org/2021/xbrl-csv`. Designed for high-volume regulatory returns (banking, insurance) where one report is millions of facts and a JSON object per fact is untenable.

The metadata defines `tableTemplates` — each with `columns` that are either *fact columns* (each cell is a fact value) or *property columns* (each cell supplies a dimension value for other columns in the row). `dimensions` objects at report, template, table, and column level layer defaults on top of each other; `parameters` and `$-references` let one template serve many tables.

Unless you are implementing an EBA/EIOPA-style return, you are unlikely to meet it. Know it exists so you recognise a `.json` next to a pile of `.csv` files as one report rather than a data dump.

## What the OIM does not cover

The model is deliberately **report-only**. It says nothing about taxonomy content — no labels, no presentation trees, no calculation networks, no hypercubes. That work is in progress as *Core Taxonomy Information* (public working draft) and the OIM Taxonomy Requirements.

So: the OIM is the right shape for the fact data. Concept metadata still has to come from the DTS.
