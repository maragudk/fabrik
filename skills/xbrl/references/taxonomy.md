# Taxonomies, linkbases, and the DTS

A taxonomy is an XML Schema plus a set of linkbases. The schema declares concepts; the linkbases say what they mean, what they are called, how they are laid out, and how they add up.

## Contents

- [Concepts](#concepts)
- [Item types](#item-types)
- [The Data Types Registry](#the-data-types-registry)
- [Extensible enumerations](#extensible-enumerations)
- [The DTS and how it is discovered](#the-dts-and-how-it-is-discovered)
- [XLink in XBRL](#xlink-in-xbrl)
- [The five standard linkbases](#the-five-standard-linkbases)
- [Label roles](#label-roles)
- [Calculations](#calculations)
- [Prohibition and overriding](#prohibition-and-overriding)
- [The rest of the spec family](#the-rest-of-the-spec-family)
- [Taxonomy packages](#taxonomy-packages)

## Concepts

A concept is an XML Schema global element declaration in the `xbrli:item` or `xbrli:tuple` substitution group.

```xml
<xs:element id="fsa_Revenue" name="Revenue"
            type="xbrli:monetaryItemType"
            substitutionGroup="xbrli:item"
            xbrli:periodType="duration"
            xbrli:balance="credit"
            nillable="true"/>
```

The pieces:

- **`name`** — must be unique within the schema. The concept's identity is `(targetNamespace, name)`.
- **`type`** — one of the XBRL item types or a restriction of one. Determines whether facts are numeric.
- **`substitutionGroup`** — `xbrli:item`, `xbrli:tuple`, `xbrldt:dimensionItem`, `xbrldt:hypercubeItem`, or something derived.
- **`@xbrli:periodType`** — **required on items**, `instant` or `duration`. Constrains which period shape the context may use.
- **`@xbrli:balance`** — optional, `debit` or `credit`, monetary types only. Says how the natural accounting sign maps to the reported sign.
- **`abstract="true"`** — the concept exists only to organise a hierarchy and must never appear in an instance. Presentation trees are full of these.
- **`nillable`** — whether `xsi:nil="true"` is allowed.
- **`id`** — optional but effectively required, because linkbase locators point at concepts with `href="schema.xsd#id"`. Convention is to prefix with the namespace's short name (`fsa_Revenue`) to avoid id clashes across imported schemas.

### The balance attribute

`balance` constrains the sign in the instance and the legal calculation weights:

| Concept balance | Actual account balance | Sign in the instance |
|---|---|---|
| credit | credit | positive or zero |
| credit | debit | negative or zero |
| debit | debit | positive or zero |
| debit | credit | negative or zero |

| From balance | To balance | Illegal `@weight` |
|---|---|---|
| debit | debit | negative |
| debit | credit | positive |
| credit | debit | positive |
| credit | credit | negative |

Most values are positive most of the time. `balance` is what lets a consumer decide whether "expenses: 500" should be added or subtracted when rolling up.

## Item types

XBRL 2.1 defines a base set; every taxonomy type must be one of them or a restriction of one. Only `fractionItemType` has complex content.

**Numeric** (require `unitRef`): `decimalItemType`, `floatItemType`, `doubleItemType`, `integerItemType`, `nonPositiveIntegerItemType`, `negativeIntegerItemType`, `longItemType`, `intItemType`, `shortItemType`, `byteItemType`, `nonNegativeIntegerItemType`, `unsignedLongItemType`, `unsignedIntItemType`, `unsignedShortItemType`, `unsignedByteItemType`, `positiveIntegerItemType`, `monetaryItemType`, `sharesItemType`, `pureItemType`, `fractionItemType`.

**Non-numeric** (must not have `unitRef`): `stringItemType`, `booleanItemType`, `hexBinaryItemType`, `base64BinaryItemType`, `anyURIItemType`, `QNameItemType`, `durationItemType`, `dateTimeItemType`, `timeItemType`, `dateItemType`, `gYearMonthItemType`, `gYearItemType`, `gMonthDayItemType`, `gDayItemType`, `gMonthItemType`, `normalizedStringItemType`, `tokenItemType`, `languageItemType`, `NameItemType`, `NCNameItemType`.

`monetary`, `shares`, and `pure` are XBRL's own additions to XML Schema's set: money, share counts, and dimensionless ratios. `dateTimeItemType` uses `xbrli:dateUnion` (date or dateTime), and note that **dates are not numeric**.

New types are made only by restriction:

```xml
<xs:complexType name="stateProvinceItemType">
  <xs:simpleContent>
    <xs:restriction base="xbrli:tokenItemType">
      <xs:enumeration value="MI"/>
      <xs:enumeration value="ON"/>
    </xs:restriction>
  </xs:simpleContent>
</xs:complexType>
```

## The Data Types Registry

The DTR (`http://www.xbrl.org/dtr/type/...`) adds standard types beyond the base set. Widely used ones:

| Type | Purpose |
|---|---|
| `textBlockItemType` | a block of narrative, possibly containing XHTML |
| `escapedItemType`, `xmlNodesItemType`, `xmlItemType` | markup-bearing string types |
| `domainItemType` | marks an element as existing only to be a dimension member |
| `percentItemType` | a pure value intended to be *displayed* as a percentage (still stored as a decimal) |
| `perShareItemType`, `monetaryPerAreaItemType`, `monetaryPerDurationItemType`, `monetaryPerEnergyItemType`, … | monetary ratios |
| `noDecimalsMonetaryItemType`, `nonNegativeMonetaryItemType` | constrained monetary |
| `areaItemType`, `massItemType`, `energyItemType`, `volumeItemType`, `lengthItemType`, `powerItemType`, `temperatureItemType`, `ghgEmissionsItemType`, … | physical quantities, used heavily by sustainability taxonomies |
| `noLangStringItemType`, `noLangTokenItemType` | strings to which `xml:lang` does not apply |
| `SQNameItemType`, `SQNamesItemType`, `prefixedContentItemType` | prefixed-content values |
| `gYearListItemType` | a list of years |

The OIM designates a subset as *supported DTR types* and gives them special treatment — notably `domainItemType` and the no-lang types, which are excluded from the definition of a "text fact" and therefore take no language dimension.

Physical-quantity types are the ones the Units Registry validates against.

## Extensible enumerations

`xs:enumeration` cannot be extended by an extension taxonomy and its values cannot be labelled in multiple languages. Extensible Enumerations 2.0 fixes both by drawing values from a dimensional domain.

A concept gets type `enum2:enumerationItemType` (single value) or `enum2:enumerationSetItemType` (a set), plus attributes:

- `@enum2:domain` — the domain head, an item
- `@enum2:linkrole` — the extended link role in which to walk `domain-member` arcs
- `@enum2:headUsable` — whether the head itself is a legal value

Values in the instance are **expanded name URIs**, not QNames: `namespace#localName`. Set values are space-separated, must be unique, and must be **lexicographically ordered** — which exists specifically so set equality is a string comparison.

```xml
<tax:CountryOfIncorporation contextRef="c1"
  >http://example.com/countries#Denmark</tax:CountryOfIncorporation>
```

Namespace `http://xbrl.org/2020/extensible-enumerations-2.0`. Version 1.0 (`http://xbrl.org/2014/extensible-enumerations`) is still in use and only supports single values; 1.1 was withdrawn.

## The DTS and how it is discovered

A **Discoverable Taxonomy Set** is the transitive closure of everything reachable from a starting document. The instance itself is *not* part of its own DTS.

**Schemas** enter the DTS when referenced by:

1. `schemaRef`, `roleRef`, `arcroleRef`, or `linkbaseRef` in an instance
2. `xs:import` or `xs:include` in a discovered schema
3. `xlink:href` on a `loc` in a discovered linkbase
4. `xlink:href` on a `roleRef` in a discovered linkbase
5. `xlink:href` on an `arcroleRef` in a discovered linkbase
6. `linkbaseRef` in a discovered schema

**Linkbases** enter when referenced by:

1. `linkbaseRef` in an instance
2. `linkbaseRef` in a discovered schema
3. being embedded at `//xs:schema/xs:annotation/xs:appinfo/*` in a discovered schema
4. `xlink:href` on a `loc` in a discovered linkbase pointing at a resource in them

`xs:redefine` is prohibited in taxonomy schemas, so it plays no part.

Discovery is transitive and every reference **must** resolve. For a real filing this is dozens to hundreds of HTTP fetches against `xbrl.org`, `xbrl.ifrs.org`, `xbrl.fasb.org`, `xbrl.dcca.dk`, and so on. Taxonomy packages (below) exist to make this offline and reproducible.

## XLink in XBRL

Linkbases are XLink documents. The vocabulary you need:

- **Simple links** — `schemaRef`, `linkbaseRef`, `roleRef`, `arcroleRef`. Just `xlink:type="simple"` plus `xlink:href`.
- **Extended links** — the five linkbase element types. Each carries `xlink:role`, which defines a **base set**: relationships in different roles are separate networks.
- **Locators** (`link:loc`) — `xlink:href` to a concept (`schema.xsd#concept_id`) plus an `xlink:label` used locally.
- **Resources** — `link:label`, `link:reference`, `link:footnote`. Carry `xlink:label` and `xlink:role`.
- **Arcs** — connect `xlink:from` label to `xlink:to` label, with `xlink:arcrole` giving the semantics, plus `@order`, `@use`, `@priority`.

A **base set** is the set of relationships sharing an element type, an `xlink:role`, and an `xlink:arcrole`. This is the unit within which networks are computed and cycles are checked.

Custom roles and arcroles are declared with `link:roleType`/`link:arcroleType` in a schema's `appinfo`, and must be declared before use with `roleRef`/`arcroleRef` in any document that uses them.

## The five standard linkbases

| Element | Arcrole | What it says |
|---|---|---|
| `link:labelLink` | `.../arcrole/concept-label` | concept → human-readable text, per language and role |
| `link:referenceLink` | `.../arcrole/concept-reference` | concept → citation of authoritative literature |
| `link:presentationLink` | `.../arcrole/parent-child` | concept → concept, display hierarchy and order |
| `link:calculationLink` | `.../arcrole/summation-item` | concept → concept, with a weight; totals |
| `link:definitionLink` | four base arcroles plus all the dimensional ones | concept → concept, semantic relationships |

All arcrole URIs above are under `http://www.xbrl.org/2003/`.

Linkbases may be separate documents or embedded in a schema's `appinfo`.

**Presentation** builds a hierarchy for display. Directed cycles are forbidden. `@preferredLabel` on a `presentationArc` names the label role to use for the child at that position — which is how one `Cash` concept shows as "Cash and cash equivalents at beginning of period" in one place and "…at end of period" in another.

**Definition** carries four base arcroles beyond the dimensional ones:

- `general-special` — the target is a specialisation of the source. Directed cycles forbidden.
- `essence-alias` — the two concepts are definitionally the same thing. Their values must be consistent where both are reported, and a processor may infer a missing *essence* value from its aliases. The reverse is explicitly not defined: the spec gives no rules for inferring an alias from an essence. Both ends must share item type and `periodType`, and `balance` where present on both. Directed cycles forbidden.
- `similar-tuples` — two tuples mean the same thing despite different content models. Symmetric; cycles fine.
- `requires-element` — if the source appears, the target must too. Cycles fine.

`essence-alias` and `general-special` are rare in modern taxonomies. `requires-element` shows up in form-like reporting.

## Label roles

The default label role is `http://www.xbrl.org/2003/role/label` (or an omitted `@xlink:role`). Others, all under `http://www.xbrl.org/2003/role/` unless noted:

| Role | Use |
|---|---|
| `terseLabel`, `verboseLabel` | shorter / more self-contained wordings |
| `totalLabel` | when the concept is presented as a total |
| `periodStartLabel`, `periodEndLabel` | for instant concepts shown as opening/closing balances |
| `positiveLabel`, `negativeLabel`, `zeroLabel` (+ Terse/Verbose variants) | wording that depends on the sign of the value |
| `documentation` | prose explaining the concept |
| `definitionGuidance`, `disclosureGuidance`, `presentationGuidance`, `measurementGuidance`, `commentaryGuidance`, `exampleGuidance` | authoring guidance |

From the Link Role Registry, under `http://www.xbrl.org/2009/role/` (2006 for `restatedLabel`):

`negatedLabel`, `negatedTerseLabel`, `negatedTotalLabel`, `negatedNetLabel`, `negatedPeriodStartLabel`, `negatedPeriodEndLabel`, `netLabel`, `deprecatedLabel`, `deprecatedDateLabel`, `restatedLabel`, and the `positivePeriod*`/`negativePeriod*` family.

**The negated roles flip the sign for display only.** A concept with `balance="debit"` reported as `500` and presented with `negatedLabel` displays as `(500)`. The fact is still positive 500. Storing the negated value is a real and damaging bug.

Every `link:label` requires `@xml:lang`.

### Other registered arcroles worth knowing

| Arcrole | Meaning |
|---|---|
| `http://www.xbrl.org/2009/arcrole/fact-explanatoryFact` | a fact explains another fact |
| `http://www.xbrl.org/2013/arcrole/parent-child` | generic presentation over arbitrary DTS elements |
| `http://www.esma.europa.eu/xbrl/esef/arcrole/wider-narrower` | ESEF anchoring: source is wider in scope than target |
| `http://www.xbrl.org/2009/arcrole/dep-concept-deprecatedConcept` and the `dep-*` family | what replaces a deprecated concept |
| `https://xbrl.org/2023/arcrole/summation-item` | Calculations 1.1 |

## Calculations

An XBRL 2.1 `summation-item` relationship says: within an extended link role, the *total concept* is the weighted sum of its *contributing concepts*, for facts that share a context and unit.

Binding conditions (2.1): the total exists; at least one contributing item exists that is c-equal and u-equal to it and is a descendant of the total's parent; nothing is nil; and **neither the total nor any contributor has a duplicate**. The total is computed by rounding each contributor to its (possibly inferred) decimals, multiplying by its weight, summing, then rounding to the total's decimals.

Multiple decompositions of the same total (cash by branch, by account type, by availability) must be put in **different extended link roles**, or they will double count.

That is the theory. In practice XBRL 2.1 calculations have two known defects: rounding causes spurious failures, and the presence of any duplicate silently disables the check entirely — which, given iXBRL, is most of the time.

**Calculations 1.1** replaces the semantics. A new arcrole, `https://xbrl.org/2023/arcrole/summation-item`, forms an entirely independent network from the 2.1 one. Key differences:

- Binding uses OIM **dimensional alignment** — all dimensions except concept must be equal — rather than context/unit string equality, and it works on data points, so tuples are out of scope.
- Consistency is **interval arithmetic**. Each fact's `decimals` implies a closed interval (`[v − 0.5×10^−d, v + 0.5×10^−d]`, or a point for `INF`). Contribution intervals are summed and the calculation is consistent if the result overlaps the reported total's interval.
- Two **rounding modes**, `round-to-nearest` and `truncation`, both required of a processor and chosen at run time for the whole report.
- Duplicates are handled rather than fatal: consistent duplicates intersect their intervals; inconsistent duplicates raise an error for that binding.
- Facts with digits beyond their declared precision raise `calc11e:excessDigits`.
- Both source and target must be `xsd:decimal`-derived.

Error codes: `calc11e:inconsistentCalculationUsingRounding`, `calc11e:inconsistentCalculationUsingTruncation`, `calc11e:excessDigits`, `calc11e:duplicateCalculationRelationships`, `calc11e:nonDecimalItemNode`, `oime:disallowedDuplicateFacts`.

Calculation inconsistencies do not invalidate a report. Filing programmes decide whether to reject on them.

## Prohibition and overriding

Extension taxonomies modify base taxonomies without editing them, via two arc attributes:

- **`@use`** — `optional` (default) or `prohibited`.
- **`@priority`** — an integer, default 0.

### Equivalence

The rules operate on sets of **equivalent** relationships, and the definition is fussier than it looks. Two relationships in the same base set are equivalent when their arcs have the same number of non-exempt attributes, each non-exempt attribute has an s-equal counterpart on the other arc, and the from-side and to-side fragments are identical.

**Exempt** attributes are `@use`, `@priority`, and everything in the `xmlns` and `xlink` namespaces. That exemption is the whole mechanism: `use` and `priority` must be exempt or a prohibiting arc could never be equivalent to the arc it prohibits, and the xlink attributes are exempt because a base set already fixes the element type, `xlink:role`, and `xlink:arcrole`. Comparison happens on the post-schema-validation infoset, so defaulted and fixed attribute values count.

### The four rules

Applied to each set of equivalent relationships:

1. A prohibiting relationship is **never itself** in the network.
2. If exactly one relationship has the highest priority and it is not prohibiting, it is included and all others are excluded.
3. If several tie for highest priority and none is prohibiting, exactly one is included — which one is application-dependent, and it does not matter because they are equivalent.
4. If **any** relationship tied for highest priority is prohibiting, **none** of the set is included.

Two consequences that catch people:

- It is "any of the tied highest", not "the highest". A prohibiting arc at priority 4 kills the set even if an optional arc also sits at priority 4.
- **Prohibition is not permanent.** An optional arc at a *higher* priority than an existing prohibiting arc resurrects the relationship (rule 2). A third-party extension can undo an earlier extension's prohibition.

The canonical use: inserting a subtotal into an existing calculation. You add arcs from the new subtotal to the children and from the total to the subtotal, and you *prohibit* the original direct arcs — otherwise the children are counted twice.

A network, once the rules are applied, is the set of relationships whose arcs share element name, namespace, and `@xlink:arcrole`, whose containing extended links share element name, namespace, and `@xlink:role`, and which are not prohibited, prohibiting, or overridden.

Any consumer computing networks from a real extension taxonomy must implement this. It is not optional in practice; ESEF and SEC extension taxonomies use it heavily.

## The rest of the spec family

Beyond the core, XBRL is a family of layered specifications. Most integrations never implement these, but a reference should tell you what exists and when it matters.

**Formula 1.0** (Recommendation, 2009) is the big one, and the one you are most likely to meet without expecting to: it is how regulators express validation rules that the base spec cannot. Rules live in a formula linkbase in the DTS, so a taxonomy you load may carry hundreds of them. Four processing models:

- **Value assertions** — an XPath 2.0 boolean test over facts selected by filters. The workhorse.
- **Existence assertions** — count what the filters found; used for "this must be reported".
- **Formula** — produce an output fact rather than a boolean. Used for derivation, mapping between taxonomies, and computing ratios.
- **Consistency assertions** — compare a formula's output against a matching reported fact, within a tolerance.

Facts reach a rule through **filters** (concept, dimension, period, entity, unit, value, relative, boolean, match, tuple, general XPath, aspect cover, concept relation). The subtle part is **implicit filtering**: variables in one rule covary on every aspect nobody explicitly covered, so `beginningBalance + changes = endingBalance` binds per entity, per period, per dimension combination without you saying so. Supporting specs cover variables, custom functions, generic and validation messages, and **Assertion Severity** (2.0, 2022) for classifying results as error/warning/ok. `xf` is a human-readable surface syntax; **OIM-compatible Formula** is a Candidate Recommendation, and **XBRL Rules and Query 3.0** is a public working draft of a successor language.

You almost certainly do not want to implement Formula. Run Arelle.

**Table Linkbase 1.0** (Recommendation, 2014, errata 2024) defines rendering tables — breakdowns, aspect nodes, rule nodes, relationship nodes — so a taxonomy can specify the actual grid a reporting template appears in. Central to EBA/EIOPA-style regulatory returns, mostly absent from financial reporting taxonomies.

**Generic Links 1.0** (2009), with **Generic Labels**, **Generic References**, and **Generic Preferred Label**, extend labelling and referencing to arbitrary DTS elements. Necessary because a standard `link:label` can only attach to a concept — a role, an arcrole, or a table node needs the generic mechanism.

**Versioning 1.0** (Recommendation, 2013) expresses machine-readable diffs between two versions of a taxonomy: concept use, concept details, dimensions. Useful in principle for migrating stored data across annual taxonomy releases; thinly adopted in practice, so most people diff the schemas themselves or follow the `dep-*` deprecation arcroles.

**XBRL GL** (Global Ledger) is a separate framework for transaction-level and ledger data rather than reported summaries. Different taxonomy, different problem; it uses tuples heavily.

**Filing Indicators 1.0** (Proposed Recommendation) lets a regulatory return say which templates it is reporting — distinguishing "reported as empty" from "not reported". **Streaming Extensions** (Candidate Recommendation, 2015) constrains document order so large instances can be processed without buffering; never widely adopted. **Digital Signatures** is a Candidate Recommendation from 2025.

## Taxonomy packages

A ZIP with a fixed shape, so a taxonomy can be resolved offline:

```
some-taxonomy-2025/          <- single top-level directory, not named META-INF
  META-INF/
    taxonomyPackage.xml      <- required
    catalog.xml              <- optional
  www.example.com/...        <- the actual schema and linkbase files
```

`taxonomyPackage.xml` carries `identifier`, `name`, `description`, `version`, `license`, `publisher`, `publisherURL`, `publisherCountry`, `publicationDate`, and an ordered list of `entryPoint` elements. Each entry point has one or more `entryPointDocument/@href` — the starting points for DTS discovery. `name`, `description`, and `publisher` are multi-lingual (repeated with `@xml:lang`).

`catalog.xml` is a restricted XML Catalog containing only `rewriteURI` entries:

```xml
<rewriteURI uriStartString="http://www.example.com/part1/2025-01-01/"
            rewritePrefix="../part1/2025-01-01/"/>
```

Relative `rewritePrefix` values resolve against the catalog's own location, which is inside `META-INF/`, hence the `../`. No two `rewriteURI` entries may share a `uriStartString`.

A processor applies these rewrites to **every** URL it resolves during processing. This is the mechanism that turns "fetch 200 documents from the internet" into "read 200 files from a ZIP".

### Report packages

The report-side analogue, for shipping a filing with its extension taxonomy:

```
my-report/                   <- single top-level directory (the "STLD")
  META-INF/
    reportPackage.json       <- optional in .zip, required in .xbr/.xbri
    taxonomyPackage.xml      <- if present, must be a valid taxonomy package
    catalog.xml
  reports/                   <- required
    report.xhtml
```

The `documentType` in `reportPackage.json` selects the package type, and the extension must match:

| documentType | Type | Extension |
|---|---|---|
| `https://xbrl.org/report-package/2023/xbri` | one Inline XBRL document set | `.xbri` |
| `https://xbrl.org/report-package/2023/xbr` | one XML or JSON-rooted report | `.xbr` |
| `https://xbrl.org/report-package/2023` | unconstrained, any number of reports | `.zip` |

Report discovery: if `reports/` directly contains any file with a recognised extension (`.xbrl`, `.xhtml`/`.html`/`.htm`, `.json`), each is a report and subdirectories are ignored. Otherwise each *direct* subdirectory of `reports/` is examined — all-HTML means one Inline XBRL document set, a single recognised file means one report, anything else is an error. So a multi-file iXBRL document set must live in a subdirectory.

Remappings from `catalog.xml` apply only if the package is also a taxonomy package, and only to taxonomy and XBRL metadata URLs — never to images, CSS, or scripts referenced by the HTML.
