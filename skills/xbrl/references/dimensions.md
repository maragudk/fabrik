# XBRL Dimensions (XDT)

Dimensions 1.0 is the specification that lets a taxonomy say "revenue, *by geography, by product line*" without defining a concept per combination. It is layered on top of XBRL 2.1 using the definition linkbase and two small namespaces. Every modern taxonomy uses it.

## Contents

- [Why it exists](#why-it-exists)
- [Namespaces](#namespaces)
- [The taxonomy side](#the-taxonomy-side)
- [The instance side](#the-instance-side)
- [Dimension defaults](#dimension-defaults)
- [Validation](#validation)
- [Practical recommendations](#practical-recommendations)
- [Reading dimensions without a taxonomy](#reading-dimensions-without-a-taxonomy)

## Why it exists

XBRL 2.1 gives every fact an entity, a period, and a unit. Everything else — the segment, the product, the currency of denomination, whether the figure is actual or restated — has to go somewhere. The base spec left `segment` and `scenario` as free-form XML containers and said "put it there". Dimensions 1.0 standardised what goes in them.

The model is the familiar one from data warehousing. A **hypercube** is a set of **dimensions**; each dimension has a **domain** of **members**; a **primary item** is attached to hypercubes and thereby constrained to be reported only at valid coordinates.

## Namespaces

| Prefix | Namespace | Where |
|---|---|---|
| `xbrldt` | `http://xbrl.org/2005/xbrldt` | taxonomy: substitution groups and arc attributes |
| `xbrldi` | `http://xbrl.org/2006/xbrldi` | instance: `explicitMember`, `typedMember` |
| `xbrldte` | `http://xbrl.org/2005/xbrldt/errors` | taxonomy error codes |
| `xbrldie` | `http://xbrl.org/2005/xbrldi/errors` | instance error codes |

Note the mismatched years — `xbrldt` is 2005, `xbrldi` is 2006. Easy to typo.

## The taxonomy side

Four kinds of element declaration, distinguished by substitution group:

| Kind | Substitution group | Must be abstract? |
|---|---|---|
| Hypercube | `xbrldt:hypercubeItem` | yes |
| Dimension | `xbrldt:dimensionItem` | yes |
| Primary item | `xbrli:item`, and neither of the above | no |
| Domain member | `xbrli:item`, and neither of the above | no |

Primary items and domain members are *the same kind of declaration*. Whether an element is a primary item or a member is decided by how it is used, not by how it is declared. One element can be both — reported as a fact in one place and used as a dimension member in another. (It may not be a member of its own dimension's domain, though; that is `xbrldte:PrimaryItemPolymorphismError`.)

`@xbrli:balance`, `@xbrli:periodType`, and `@nillable` on hypercube and dimension declarations are meaningless — they are only there because XML Schema requires a type.

### The arcroles

All are used on `link:definitionArc`.

| Arcrole URI | From → To | Cycles |
|---|---|---|
| `http://xbrl.org/int/dim/arcrole/all` | primary item → hypercube | undirected |
| `http://xbrl.org/int/dim/arcrole/notAll` | primary item → hypercube | undirected |
| `http://xbrl.org/int/dim/arcrole/hypercube-dimension` | hypercube → dimension | none |
| `http://xbrl.org/int/dim/arcrole/dimension-domain` | dimension → domain member | none |
| `http://xbrl.org/int/dim/arcrole/domain-member` | member → member | undirected only |
| `http://xbrl.org/int/dim/arcrole/dimension-default` | dimension → member | none |

`all` and `notAll` are collectively the **has-hypercube** relationships.

### Consecutive relationships and the DRS

A **dimensional relationship set (DRS)** is a chain of relationships followed across base sets, not just within one. Two relationships are consecutive when the arcroles form one of these ordered pairs *and* the target nodes of the first are the source nodes of the second:

```
all            → hypercube-dimension
notAll         → hypercube-dimension
hypercube-dimension → dimension-domain
dimension-domain    → domain-member
domain-member       → domain-member
```

`@xbrldt:targetRole` on an arc redirects the chain into a different extended link role, which is how taxonomies split a large structure across link roles while keeping the chain connected. `dimension-default` is not subject to `targetRole`.

### Attributes on has-hypercube arcs

- **`@xbrldt:contextElement`** — required, `segment` or `scenario`. Says which container the dimensions must appear in for this hypercube.
- **`@xbrldt:closed`** — optional boolean, default `false`. If true, the context may contain *no dimensions beyond* those in this hypercube (in the relevant container). If false, extra dimensions are unconstrained.

### Attributes on dimension-domain and domain-member arcs

- **`@xbrldt:usable`** — optional boolean, default `true`. `false` excludes the arc's target from the set of valid members while leaving it in the hierarchy for organisation. Exclusion does not propagate to that member's own children. If one path marks a member unusable and another marks it usable, unusable wins.

### Inheritance

If a primary item is the source of both a `domain-member` relationship and a `has-hypercube` relationship, the target of the `domain-member` relationship **inherits** the hypercube — transitively, preserving base set, `contextElement`, and `closed`. This is how a taxonomy attaches one hypercube to a whole statement's worth of line items with a single arc.

### Explicit vs typed dimensions

An **explicit dimension** enumerates its members in the taxonomy. Its domain is built by walking `dimension-domain` then `domain-member` arcs and collecting usable members' QNames. The domain root — the target of `dimension-domain` — counts as a valid member itself, unless that arc carries `xbrldt:usable="false"`.

A **typed dimension** has an `@xbrldt:typedDomainRef` pointing (as a URI with a fragment) at a global, non-abstract element declaration in a schema in the DTS. The domain is "whatever validates against that element". Used when enumeration is impractical: customer numbers, phone numbers, tranche identifiers.

```xml
<xs:element name="CustomerDim" id="tax_CustomerDim" abstract="true"
            substitutionGroup="xbrldt:dimensionItem" type="xbrli:stringItemType"
            xbrli:periodType="duration"
            xbrldt:typedDomainRef="dims.xsd#id_cust"/>
```

The separation of the dimension element from the domain element exists because definition-linkbase arcs may only target `xbrli:item`/`xbrli:tuple` members, and forcing that restriction on the domain content would be pointless.

## The instance side

Dimension values go inside `segment` or `scenario` — whichever the hypercube's `@xbrldt:contextElement` says.

```xml
<xbrli:context id="c1">
  <xbrli:entity>
    <xbrli:identifier scheme="http://www.dcca.dk/cvr">12345678</xbrli:identifier>
  </xbrli:entity>
  <xbrli:period><xbrli:instant>2025-12-31</xbrli:instant></xbrli:period>
  <xbrli:scenario>
    <xbrldi:explicitMember dimension="tax:GeographyAxis">geo:Denmark</xbrldi:explicitMember>
    <xbrldi:typedMember dimension="tax:CustomerDim">
      <d:cust>12345</d:cust>
    </xbrldi:typedMember>
  </xbrli:scenario>
</xbrli:context>
```

`xbrldi:explicitMember` has a required `@dimension` (QName) and QName content. `xbrldi:typedMember` has a required `@dimension` and exactly one child element of any type.

**Both the `@dimension` attribute and the `explicitMember` content are QNames in text position.** No XML parser resolves them for you. Resolve against the namespace bindings in scope at that element, or dimensional comparison across filings from different software will silently fail.

A context must not contain more than one value for the same dimension (`xbrldie:RepeatedDimensionInInstanceError`).

## Dimension defaults

A `dimension-default` arc declares one member as the dimension's default. Then:

- The default member **must never appear** in a context (`xbrldie:DefaultValueUsedInInstanceError`).
- A fact with the dimension absent is understood to have the default value.
- The default is **global**: declared once anywhere, it applies in every extended link role where the dimension is used.
- A dimension may have at most one default.
- The default arc does not add its target to any domain.

The purpose is to make totals work. If `ProductAxis` defaults to `AllProducts`, then a `GrossProfit` fact with no product dimension is the all-products figure, and it can participate in calculation relationships with facts that also carry no product dimension.

For a consumer this means **you cannot reliably tell whether two facts are the same data point without the taxonomy**, because one may carry an explicit member and the other may be relying on a default. Instance-only readers should carry the dimensions as written and let a taxonomy-aware layer normalise later.

## Validation

Dimensional validation is per fact, not per document:

1. Find every hypercube reachable from the fact's concept via `has-hypercube` relationships (including inherited ones).
2. Group them by base set.
3. Within a base set, a hypercube is individually valid when, for each of its dimensions, the context has a member from that dimension's domain of valid members (or the dimension has a default and is absent). If `closed="true"`, the context must additionally have no dimensions outside the hypercube in the relevant container.
4. Combine within the base set: `all` hypercubes must be valid, `notAll` hypercubes must be invalid.
5. The fact is dimensionally valid if **at least one base set** yields a valid combination.
6. A concept with no hypercubes at all is unconstrained — always valid.

That last point is why the Use-of-Dimensions guidance recommends attaching every concept to at least one hypercube, even an empty one: otherwise anything at all can be written into `segment`/`scenario` for that concept and nothing checks it.

## Practical recommendations

From the *Technical Considerations for the use of XBRL Dimensions* working group note — these are taxonomy design guidance, but they explain what you will and will not see:

- **Pick one of `segment` and `scenario` and use it exclusively.** New taxonomies should use `scenario`. In practice you must read both, because you consume taxonomies you did not design.
- **`segment`/`scenario` should contain only dimensions**, nothing else. The base spec allows arbitrary XML there; treat anything else as a legacy oddity.
- **All positive hypercubes should be closed.** An open hypercube validates nothing about the dimensions it does not mention.
- **Negative (`notAll`) hypercubes only make sense alongside a positive one in the same base set**, and should be open.
- **Defaults should only be the natural total of a domain.** An arbitrary default silently attaches a member to every fact that omits the dimension.
- **Typed dimensions should use simple types only.** Complex-typed domains have no labelling mechanism, so tools end up showing raw XML to users.

## Reading dimensions without a taxonomy

You can extract dimensions from an instance with no taxonomy at all — you just cannot validate them or infer defaults. A reasonable instance-only model:

```
Dimension {
    Axis   QName   // from @dimension, prefix resolved
    Member QName   // explicitMember content, prefix resolved — empty for typed
    Typed  string  // typed dimension value as text — empty for explicit
}
```

Collect from both `segment` and `scenario` and keep them in one list; the container is a taxonomy design detail, not information about the fact.

Two caveats. First, a typed dimension whose value is structured (a complex type with child elements) does not fit a `string`. Refusing such a document is more honest than silently storing an empty value. Second, without the taxonomy you cannot tell an explicit dimension from a typed one *a priori* — but you do not need to, because the instance tells you via which container element was used.
