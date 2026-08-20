---
name: xbrl
description: Guide for working with XBRL, the standard for digital business and financial reporting -- reading and writing instance documents, Inline XBRL (iXBRL), xBRL-JSON and xBRL-CSV, taxonomies and linkbases, dimensions, contexts, units, and facts. Use this skill whenever the user touches XBRL in any form -- parsing or generating an instance, extracting figures from a filing or annual report, handling `xbrli:context`, `contextRef`, `unitRef`, `decimals`/`precision`, `ix:nonFraction`, `ix:nonNumeric`, `ix:hidden`, `xbrldi:explicitMember`, `xbrldi:typedMember`, hypercubes, DTS discovery, taxonomy or report packages, or the Open Information Model. Triggers even when the word "XBRL" never appears -- ESEF, iXBRL, SEC EDGAR company facts, `us-gaap:`/`ifrs-full:`/`dei:` prefixed tags, financial statement tagging, or a file arriving as `.xbrl`/`.xbri`/`.xbr` are all enough.
license: MIT
---

# XBRL

XBRL is the global standard for digital business reporting: a way to state facts about a business so software can find them without reading prose. Regulators in most of the world now mandate it, which means the data arrives whether or not you asked for it in a convenient shape.

This file is the overview and a router. Deep detail lives in `references/`.

## Mental model

XBRL splits a business report in two:

- **The report** (an *instance*, or in OIM language an *XBRL report*) holds the facts: the numbers and text a company actually reported.
- **The taxonomy** holds the definitions: what `fsa:Revenue` means, what type it has, what it is called in Danish, what it sums into, which dimensions may qualify it.

A **fact** is a value plus the coordinates that say what it is a value of. In the XML syntax those coordinates are spread across three places:

```xml
<fsa:Revenue contextRef="c1" unitRef="DKK" decimals="-3">12450000</fsa:Revenue>

<xbrli:context id="c1">
  <xbrli:entity>
    <xbrli:identifier scheme="http://www.dcca.dk/cvr">12345678</xbrli:identifier>
  </xbrli:entity>
  <xbrli:period>
    <xbrli:startDate>2025-01-01</xbrli:startDate>
    <xbrli:endDate>2025-12-31</xbrli:endDate>
  </xbrli:period>
</xbrli:context>

<xbrli:unit id="DKK">
  <xbrli:measure>iso4217:DKK</xbrli:measure>
</xbrli:unit>
```

Read as: *this entity, over this period, reported revenue of 12,450,000 DKK, accurate to the nearest thousand.*

The modern framing, from the **Open Information Model (OIM)**, is cleaner and worth adopting internally even when you parse XML: a fact is a **value**, a **decimals**, and a **set of dimensions**. Five are built in for ordinary facts — `concept`, `entity`, `period`, `unit`, `language` (a sixth, `noteId`, exists only on footnote facts) — and any others come from the taxonomy. Contexts and units are XML plumbing for grouping dimensions; they carry no meaning of their own. Two contexts with different `id`s but identical content are the same coordinates.

Everything else in XBRL is elaboration on that: dimensions add coordinates, linkbases add meaning, iXBRL wraps it in HTML, and the OIM formats re-serialise it.

## Which format am I holding?

| Looks like | It is | Notes |
|---|---|---|
| Root `<xbrl>` or `<xbrli:xbrl>` | **xBRL-XML** instance (XBRL 2.1) | The classic. Facts are elements. |
| Root `<html>` with `xmlns:ix="http://www.xbrl.org/2013/inlineXBRL"` | **Inline XBRL 1.1** | A report you can open in a browser with facts woven in. What regulators mandate today. |
| `<html>` with `ix` bound to `.../2008/inlineXBRL` | **Inline XBRL 1.0** | Older, different namespace, rarer. |
| JSON with `/documentInfo/documentType` = `https://xbrl.org/2021/xbrl-json` | **xBRL-JSON** | Flat, friendly, rarely published in the wild. |
| JSON with documentType `https://xbrl.org/2021/xbrl-csv` plus CSV files | **xBRL-CSV** | Bulk/regulatory returns. Metadata JSON + data tables. |
| ZIP with a single top dir containing `reports/` | **Report package** | `.xbri` = one iXBRL doc set, `.xbr` = one XML/JSON report, `.zip` = unconstrained. |
| ZIP with `META-INF/taxonomyPackage.xml` | **Taxonomy package** | A taxonomy plus a URL rewrite catalog. |
| `.xsd` importing `http://www.xbrl.org/2003/instance` | **Taxonomy schema** | Concept definitions. |
| `<linkbase>` in the `.../2003/linkbase` namespace | **Linkbase** | Labels, presentation, calculation, definition, references. |

An iXBRL document is **not** an instance. It *maps to* one (the "target document"). Refuse to parse it as an instance rather than silently returning zero facts — that failure mode is very hard to debug downstream.

## The one architectural decision: how much taxonomy do you need?

This dominates everything else about an XBRL integration, so make it consciously and early.

**Without the taxonomy** you can read, from the instance alone: every fact's concept (as a namespace + local name), its raw value string, its context (entity, period, dimensions), its unit, and its claimed accuracy. That is enough for storage, diffing, provenance, and any analysis where you already know which concepts you care about. It needs no network access, no schema resolution, and no XML Schema validation. A competent instance reader is a few hundred lines.

**Only with the taxonomy** can you get: human-readable labels in any language, the data type of a concept (and therefore whether a value is a number, a date, or a text block), `periodType` and `balance` (debit/credit), presentation order and hierarchy, calculation relationships, dimensional validity, which member is a dimension's default, and enumeration domains.

Resolving a taxonomy means DTS discovery: follow `schemaRef`, then every `import`, `include`, `linkbaseRef`, `roleRef`, `arcroleRef`, and locator `href` transitively. For a real filing that is dozens to hundreds of remote documents. Taxonomy packages exist precisely so you can do it offline.

Three sane postures:

1. **Instance-only.** Treat concepts as opaque `(namespace, localName)` pairs and let the consumer decide meaning. Fast, hermetic, testable. Choose this unless you need labels or validation.
2. **Instance plus a pinned, vendored taxonomy.** Ship the taxonomy packages for the jurisdictions you support and resolve offline through the `catalog.xml` rewrites. Gets you labels and types without live network calls.
3. **Full processor.** Don't write one. Use [Arelle](https://arelle.org) as a subprocess or web service for validation, DTS resolution, and conversion to xBRL-JSON. Writing a conforming XBRL processor is a multi-year project, and the conformance suites are the reason.

There is no mature XBRL library for Go. Reading instances yourself is very tractable; anything DTS-dependent should shell out to Arelle. See [`references/parsing.md`](references/parsing.md).

## What to read next

| You are doing | Read |
|---|---|
| Parsing or writing an xBRL-XML instance: contexts, units, items, tuples, footnotes, nil, decimals | [`references/instance.md`](references/instance.md) |
| Handling Inline XBRL: `ix:` elements, extraction to a target document, transformations, scale, continuation | [`references/inline-xbrl.md`](references/inline-xbrl.md) |
| Anything with dimensions: hypercubes, explicit vs typed members, defaults, segment vs scenario, validity | [`references/dimensions.md`](references/dimensions.md) |
| Taxonomies: concepts, item types, linkbases, roles and arcroles, labels, calculations, DTS discovery, packages | [`references/taxonomy.md`](references/taxonomy.md) |
| xBRL-JSON, xBRL-CSV, the OIM model, duplicate and equality semantics | [`references/oim.md`](references/oim.md) |
| A specific filing regime: ESEF, SEC EDGAR, Danish DBA, UK; where to get taxonomies; tooling | [`references/programmes.md`](references/programmes.md) |
| Designing the parser and its data model; what to reject; storage shape; testing | [`references/parsing.md`](references/parsing.md) |

Start with `parsing.md` if the task is "build something that reads filings" — it stitches the others together into a build order.

## Gotchas that bite everyone

These are the ones that cause silent wrong answers rather than loud failures. Most of them are invisible until you run against a second filer.

**Prefixes are not identity.** A concept is a namespace URI plus a local name. The same taxonomy is bound to `fsa:` in one filing and `d:` in the next; both are the same concept. Never key on the prefix, never key on the raw QName string.

**Some QNames live where no XML parser resolves them.** Element and attribute *names* get resolved by any XML library. But `xbrldi:explicitMember` content, its `@dimension` attribute, `xbrli:measure` content, and `enum2` values are QNames written as *text*. You must resolve those against the namespace bindings in scope at that point in the document. Getting this wrong makes dimensions compare unequal across filings from different vendors.

**Facts are reported as written.** An instance may state the same fact twice with different values or different precision. That is legal, and iXBRL makes it common — good tagging practice requires every visible occurrence of a figure to be tagged. Decide a duplicate policy deliberately; see the classes (complete / consistent / inconsistent / multi-language / multi-unit) in [`references/oim.md`](references/oim.md).

**`decimals` and `precision` describe the source, not the display.** `decimals="-3"` means "correct to the nearest thousand", so the reported value is already full magnitude. They are never a scaling instruction — `12450000` with `decimals="-3"` is 12,450,000, not 12,450. Scaling in iXBRL is a separate `@scale` attribute, and the extracted value is always unscaled.

**A filing uses `precision` *or* `decimals`, and which one is a property of the filer.** Reading only `decimals` silently drops every numeric fact in filings that use `precision`. Both are optional individually but a non-nil numeric fact must carry exactly one.

**`precision="0"` means nothing is known.** Not "zero decimal places". Any comparison involving it is false and any calculation is inconsistent.

**Period end dates are exclusive-ish.** Per spec, a bare date in `endDate` or `instant` means midnight at the *end* of that day, i.e. `T00:00:00` the following day. `startDate` means midnight at the start. If you convert to half-open intervals, `endDate 2025-12-31` becomes `2026-01-01T00:00:00`. Off-by-one-day bugs here are extremely common.

**Dimensions live in `segment` *or* `scenario`.** Both are legal containers and different taxonomies choose differently — even within one jurisdiction. Read both. (New taxonomies should use `scenario` only, but you do not get to choose what arrives.)

**Dimension defaults must not appear in the instance, but must be inferred when comparing.** If a taxonomy declares a default member for an axis, a filing reporting the "total" leaves the axis off entirely. Two facts that look dimensionally different may be the same data point once defaults are applied — which requires the taxonomy.

**`xsi:nil="true"` is not zero.** It means the filer stated the value is absent. A nil fact carries no value and no `decimals`/`precision`.

**Sign lives in three places and only one of them is the value.** The value is as reported. `balance="debit"/"credit"` on the concept says how to interpret its natural sign. `negatedLabel` and friends are *presentation* roles that flip the sign for display only — never flip the stored value. Calculation weights (`-1.0`) belong to the calculation network, not the fact.

**Units are constrained by type.** Monetary facts need exactly one measure whose local name is a valid ISO 4217 code in `http://www.xbrl.org/2003/iso4217`. Shares need `xbrli:shares`. Ratios and percentages need `xbrli:pure` and must be reported as decimals, never multiplied by 100. Per-share values use `<divide>`.

**Language is inherited.** `xml:lang` on a fact, or on any ancestor including the root. A filer reporting the same concept in Danish and English in the same context is distinguishing them by nothing else.

**Old filings look different.** Older instances often declare the instance namespace as the *default* namespace, so the root is `<xbrl>` and contexts are `<context>` with no prefix. Tuples (compound facts) appear in older taxonomies and are unsupported by the OIM entirely. Encodings other than UTF-8 exist and matter the moment a name contains a non-ASCII letter.

**Calculation checks in XBRL 2.1 are disabled by any duplicate.** That is a specification defect, fixed by Calculations 1.1 (a new arcrole, `https://xbrl.org/2023/arcrole/summation-item`, with interval-based consistency). If you implement calculation checking, implement 1.1 semantics.

## Spec index

Everything is at <https://specifications.xbrl.org>, which is the authoritative catalogue including status and errata dates.

| Spec | URL |
|---|---|
| XBRL 2.1 (the core) | <https://www.xbrl.org/Specification/XBRL-2.1/REC-2003-12-31/XBRL-2.1-REC-2003-12-31+corrected-errata-2013-02-20.html> |
| XBRL Dimensions 1.0 | <https://www.xbrl.org/specification/dimensions/rec-2012-01-25/dimensions-rec-2006-09-18+corrected-errata-2012-01-25-clean.html> |
| Inline XBRL 1.1 Part 1 | <https://www.xbrl.org/Specification/inlineXBRL-part1/REC-2013-11-18+errata-2026-07-14/inlineXBRL-part1-REC-2013-11-18+corrected-errata-2026-07-14.html> |
| Transformation Rules Registry 5 | <https://www.xbrl.org/Specification/inlineXBRL-transformationRegistry/REC-2022-02-16/inlineXBRL-transformationRegistry-REC-2022-02-16.html> |
| Open Information Model 1.0 | <https://www.xbrl.org/Specification/oim/REC-2021-10-13+errata-2023-04-19/oim-REC-2021-10-13+corrected-errata-2023-04-19.html> |
| xBRL-JSON 1.0 | <https://www.xbrl.org/Specification/xbrl-json/REC-2021-10-13+errata-2023-04-19/xbrl-json-REC-2021-10-13+corrected-errata-2023-04-19.html> |
| xBRL-CSV 1.0 | <https://www.xbrl.org/Specification/xbrl-csv/REC-2021-10-13+errata-2023-04-19/xbrl-csv-REC-2021-10-13+corrected-errata-2023-04-19.html> |
| Calculations 1.1 | <https://www.xbrl.org/Specification/calculation-1.1/REC-2023-02-22+corrected-errata-2024-02-14/calculation-1.1-REC-2023-02-22+corrected-errata-2024-02-14.html> |
| Extensible Enumerations 2.0 | <https://www.xbrl.org/Specification/extensible-enumerations-2.0/REC-2020-02-12/extensible-enumerations-2.0-REC-2020-02-12.html> |
| Taxonomy Packages 1.0 | <https://www.xbrl.org/Specification/taxonomy-package/REC-2016-04-19/taxonomy-package-REC-2016-04-19.html> |
| Report Packages 1.0 | <https://www.xbrl.org/Specification/report-package/REC-2023-09-22+corrected-errata-2025-03-11/report-package-REC-2023-09-22+corrected-errata-2025-03-11.html> |
| Handling Duplicate Facts (WGN) | <https://www.xbrl.org/WGN/xbrl-duplicates/WGN-2025-01-14/xbrl-duplicates-2025-01-14.html> |
| Use of Dimensions (WGN) | <https://www.xbrl.org/WGN/dimensions-use/WGN-2015-03-25/dimensions-use-WGN-2015-03-25.html> |
| Link Role Registry 2.0 | <https://specifications.xbrl.org/registries/lrr-2.0/> |
| Data Types Registry | <https://specifications.xbrl.org/work-product-index-registries-dtr-1.1.html> |

Conformance suites (linked from the same site) are the real test of an implementation. XBRL 2.1 and Dimensions both ship one, and they are worth running against even a partial reader.
