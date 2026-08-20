# Building something that reads XBRL

Practical guidance for writing a reader, in build order. Assumes the instance-only or pinned-taxonomy posture from SKILL.md; if you need a full processor, use Arelle.

## Contents

- [Scope the reader first](#scope-the-reader-first)
- [A data model](#a-data-model)
- [Build order](#build-order)
- [Resolving QNames yourself](#resolving-qnames-yourself)
- [Fail loudly or drop quietly?](#fail-loudly-or-drop-quietly)
- [Normalising values](#normalising-values)
- [Storage](#storage)
- [Streaming and memory](#streaming-and-memory)
- [Testing](#testing)

## Scope the reader first

Write down, before any code, which of these you support. Each is a real decision with real cost, and leaving them implicit is how a reader ends up half-implementing four of them.

| Question | Cheap answer | Expensive answer |
|---|---|---|
| xBRL-XML instances? | yes | — |
| Inline XBRL? | reject with a clear error | extract the target document |
| Multiple iXBRL target documents? | default target only | all targets |
| Tuples? | reject | flatten, or model the nesting |
| Fractions? | reject | `numerator`/`denominator` pair |
| Footnotes? | ignore | model fact→note links |
| Dimensions? | carry as written | resolve against the taxonomy |
| `precision`? | carry alongside `decimals` | convert to `decimals` on read |
| Duplicates? | return all, in document order | apply a policy on read |
| Taxonomy? | none | pinned packages, or full DTS |

The cheap column is a coherent, useful reader. It answers "what did this company report" without a network connection. Most integrations never need more, and the ones that do are better served adding a taxonomy layer on top of a clean fact reader than by conflating the two.

## A data model

Modelled on the OIM, which is the right shape even when the input is XML. Shown in Go because the ideas transfer and the types are explicit; nothing here is Go-specific.

```go
// Document is one XBRL report.
type Document struct {
	Contexts map[string]Context
	Units    map[string]Unit
	Facts    []Fact // in document order
}

// Fact is one reported value plus the coordinates that say what it is a value of.
type Fact struct {
	Concept    Name   // namespace + local name, prefix already resolved
	Value      string // as written; never parsed here
	ContextRef string
	UnitRef    string
	Decimals   string // number or "INF"; empty if the filing used Precision
	Precision  string // number or "INF"; empty if the filing used Decimals
	Lang       string // BCP 47, from the fact or inherited from an ancestor
	Nil        bool   // reported as absent, not zero
}

type Context struct {
	ID         string
	Entity     Entity
	Period     Period
	Dimensions []Dimension // segment and scenario merged; container is not information
}

type Entity struct {
	Scheme     string
	Identifier string
}

// Period is exactly one of the three shapes. Instant is set for instants,
// Start/End for durations, Forever for forever.
type Period struct {
	Instant time.Time
	Start   time.Time
	End     time.Time
	Forever bool
}

type Dimension struct {
	Axis   Name   // from @dimension
	Member Name   // explicitMember content; zero for typed dimensions
	Typed  string // typed dimension value as text; empty for explicit
}

type Unit struct {
	ID          string
	Measure     Name   // simple units
	Numerator   []Name // divide
	Denominator []Name
}
```

Three deliberate choices worth copying:

**Values stay strings.** The taxonomy decides whether `0.5` is a decimal, a percentage, or a string. Parsing at read time forces a guess. Keep the lexical form; parse in the layer that knows the type.

**Both `Decimals` and `Precision` are kept.** Reading only one drops every numeric fact in filings that use the other, and the choice is a property of the filing software, not of the fact.

**Facts are a slice, not a map.** Duplicates are legal, ordering is information (it tells you where in the report a fact was), and any de-duplication policy is a caller's decision.

## Build order

1. **Detect the format.** Sniff the root element. `xbrl`/`xbrli:xbrl` → instance. `html` with an `ix` namespace → iXBRL. JSON with a `documentInfo.documentType` → an OIM format. ZIP → look for `reports/` and `META-INF/`. Get this wrong and everything downstream is confusing.
2. **Read the whole document before resolving anything.** Contexts and units may appear after the facts that reference them. There is no valid streaming order.
3. **Parse contexts.** Entity, period, dimensions from both `segment` and `scenario`.
4. **Parse units.** Resolve measure QNames.
5. **Parse facts.** Resolve concept names, capture attributes, inherit `xml:lang`.
6. **Resolve references.** Every `contextRef` and `unitRef` must hit.
7. **Then**, as separate layers: iXBRL extraction, duplicate policy, taxonomy lookup.

## Resolving QNames yourself

The one non-obvious mechanic. XML libraries resolve prefixes on element and attribute *names*. They do not resolve prefixes that appear in attribute *values* or element *content*. XBRL puts QNames in both places:

| Location | Kind |
|---|---|
| `xbrldi:explicitMember/@dimension` | attribute value |
| `xbrldi:explicitMember` content | element content |
| `xbrldi:typedMember/@dimension` | attribute value |
| `xbrli:measure` content | element content |
| `ix:nonFraction/@name`, `ix:nonNumeric/@name` | attribute value |
| `link:usedOn` content | element content |

You need the in-scope namespace bindings at the point the QName is written. Few XML libraries hand you that map directly. Two workable approaches:

- **Maintain the stack yourself.** Drive the parser token by token and push/pop bindings as you enter and leave elements. Namespace declarations arrive as ordinary attributes on the start element, so this is mechanical. In Go, `xml.Decoder.Token()` gives you what you need; `Decoder.DecodeElement` into a struct does not, because it resolves names and discards scope.
- **Resolve against the root element's bindings only.** Simpler, and it covers the overwhelming majority of real filings, because filings declare every prefix on the root. It is not correct in general — a document may bind a prefix on an inner element, and iXBRL documents legitimately do.

Whatever you choose, **document the limitation**, and prefer to fail on an unresolvable prefix rather than silently keep the raw text. A dimension stored as the literal string `d:Denmark` will compare unequal to `geo:Denmark` from the next filer, and nothing will alert you.

Watch for the default-namespace case too. Pre-2014 filings declare `xmlns="http://www.xbrl.org/2003/instance"` on the root, so unprefixed QNames in content resolve to the instance namespace, not to "no namespace".

## Fail loudly or drop quietly?

The instinct with messy real-world data is to skip what you cannot handle. For XBRL that instinct is wrong in a specific way: a fact stripped of its context is a number with nothing to say what it is a number of, and it will be silently wrong in a report rather than loudly absent.

Fail the whole parse on:

- a `contextRef` or `unitRef` naming something the document never defines
- a numeric fact with no unit, or an accuracy claim with no unit
- a context whose period is none of instant, duration, forever
- duplicate or missing `@id` on a context or unit
- content outside the root element
- structured content where you expect text (a tuple, a fraction, a complex typed dimension value) — refusing is better than reading it as empty
- an encoding you cannot decode correctly

Accept and pass through:

- duplicate facts
- facts on concepts you have never seen
- unknown attributes in foreign namespaces
- dimensions whose axes you do not recognise

The dividing line: refuse anything that would make you *misrepresent* the data; accept anything you merely do not *understand*.

## Normalising values

Three normalisations are safe without a taxonomy, and worth doing at read time because getting them wrong later is expensive:

**Dates.** Apply the end-of-day rule: bare dates in `endDate` and `instant` are that day plus one at `T00:00:00`; bare dates in `startDate` are that day at `T00:00:00`. Store as instants so period comparison is arithmetic.

**Whitespace.** Trim entity identifiers, schemes, and `xml:lang`. Do **not** trim fact values in general — a text block's whitespace can be significant, and XML Schema whitespace facets are a taxonomy-level concern.

**Language inheritance.** Resolve `xml:lang` from the fact or its nearest ancestor with one, including the root, at read time. Doing it later means keeping the tree.

Three normalisations that are **not** safe without the taxonomy, and should be left alone:

- Converting values to numbers (you do not know the type).
- Converting `precision` to `decimals` (needs the value parsed as a number, which needs the type; and it discards which form the filing used).
- Applying dimension defaults (needs the taxonomy).

## Storage

If you persist facts, the key question is what makes a row unique.

- Raw, as-parsed: the key is a synthetic id or `(document, position)`. Duplicates are preserved. Best for provenance and re-processing.
- After applying the recommended duplicate policy (reject inconsistent, drop complete duplicates, keep the most precise of consistent ones): `(dimensions, decimals)` is unique. That is the shape most analysis wants.

Dimensions do not fit a fixed column set. Either store them as a normalised child table keyed by `(fact_id, axis_namespace, axis_local)`, or as a canonical serialised string for equality comparison — sorted by axis expanded name, with members as expanded names rather than prefixed QNames. The sorted-expanded-name string doubles as a cheap dimensional-alignment key, which is exactly what Calculations 1.1 binding and duplicate detection both need.

Store the concept as two columns (namespace, local name), never as a prefixed QName string.

## Streaming and memory

Instances are usually small — hundreds to low thousands of facts. Regulatory returns in xBRL-CSV and some banking filings are not: millions of facts, hundreds of megabytes.

XBRL 2.1 defines no document order, so a conforming reader must buffer. The *Streaming Extensions* module (a Candidate Recommendation, never widely adopted) exists to allow a constrained ordering that permits streaming; you are unlikely to meet it. In practice: buffer contexts and units, and stream facts only if you can afford a second pass, or accept the memory.

iXBRL is worse than XML here, because the fact values may be spread across a continuation chain and the header may come after some facts. Two passes over a DOM is the honest approach.

## Testing

**Use real filings.** Synthetic examples all look like the spec's examples, which is not what filers produce. Get a handful from each programme you support, across a decade if the jurisdiction has that history, and from different filing software vendors — vendor differences (which prefixes, `segment` vs `scenario`, `precision` vs `decimals`) are exactly what breaks readers.

**Use the conformance suites.** XBRL 2.1 and Dimensions each ship one, downloadable from <https://specifications.xbrl.org>. They are structured as test cases with expected error codes. Even running the subset relevant to your scope finds classes of bug that real filings will not surface for months.

**Test the error paths.** The failure modes above should each have a test that asserts the parse fails, and fails with a distinguishable error. A reader that returns `(nil, nil)` for an iXBRL document is worse than one that panics.

**Test the boring normalisations.** Period end-of-day. Inherited `xml:lang`. Default-namespace instances. Prefix aliasing — the same concept written `fsa:Revenue` in one fixture and `d:Revenue` in another must compare equal.

**Cross-check against Arelle.** Converting a filing to xBRL-JSON with Arelle gives you a reference fact set to diff against. Differences are usually your bug, and occasionally a genuinely ambiguous corner of the spec — either is worth knowing about.
