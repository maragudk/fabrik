# Reporting programmes, taxonomies, and tooling

XBRL is a standard; a *reporting programme* is a regulator's rules on top of it. The spec tells you what is well-formed; the programme tells you what will be accepted. Any real integration is against a programme, not against XBRL in the abstract.

## Contents

- [The general shape of a programme](#the-general-shape-of-a-programme)
- [ESEF (European Union)](#esef-european-union)
- [SEC EDGAR (United States)](#sec-edgar-united-states)
- [Denmark](#denmark)
- [United Kingdom](#united-kingdom)
- [Where to get taxonomies](#where-to-get-taxonomies)
- [Tooling](#tooling)

## The general shape of a programme

Every programme specifies roughly the same list, and this is a good checklist when onboarding a new one:

1. **Format** — iXBRL, xBRL-XML, or an OIM format; and how it is packaged.
2. **Base taxonomy** — which taxonomy and which annual version.
3. **Extension policy** — whether filers may define their own concepts, and what they must do to relate them back.
4. **Entity identifier scheme** — the `scheme` URI and the identifier format.
5. **Required facts** — a set of concepts every filing must report (period, identity, currency, and so on).
6. **Filing rules** — technical constraints not derivable from the specs: allowed decimals, forbidden constructs, naming conventions, size limits.
7. **Validation severity** — which rules reject a filing and which merely warn.

Filing rules are the part you cannot get from a specification, and they are why Arelle ships a separate validation plugin per programme.

## ESEF (European Union)

The European Single Electronic Format. Mandatory for issuers on EU regulated markets. Governed by an ESMA Regulatory Technical Standard, with practical guidance in the **ESEF Reporting Manual** (`ESMA32-60-254`, updated roughly annually).

- **Format**: XHTML. IFRS *consolidated* financial statements must be marked up with Inline XBRL. Annual reports without consolidated IFRS statements are plain XHTML with no tagging.
- **Base taxonomy**: the ESEF taxonomy, which is the IFRS Accounting Taxonomy plus ESMA additions, published per year.
- **Entity identifier**: LEI, with scheme `http://standards.iso.org/iso/17442`, used consistently throughout the document. The XBRL International LEI taxonomy is imported into the ESEF taxonomy so the LEI can also be reported and checked as a fact. Entity identification carries a cluster of error-severity validation rules — check the current Reporting Manual for the exact set, which changes between annual updates.
- **Extensions**: permitted, and required where no base element has the right accounting meaning.
- **Anchoring**: the distinctive ESEF requirement. Every extension element in the four primary statements must be linked to the closest base-taxonomy element that is *wider* — and optionally to narrower ones — using the `http://www.esma.europa.eu/xbrl/esef/arcrole/wider-narrower` arcrole in the **definition linkbase** of the filer's extension taxonomy. Subtotals composed purely of other tagged disclosures are exempt. Notes marked up as text blocks are exempt from mandatory anchoring.
- **Block tagging**: the notes must be tagged as whole blocks (text blocks), in addition to detailed tagging of the primary statements. Detailed tagging of the notes has been phasing in.
- **Packaging**: a report package containing the XHTML and the filer's extension taxonomy.

Anchoring is the thing to plan for as a consumer: it means an ESEF filing's most interesting facts may sit on concepts that exist only in that one filer's taxonomy, and the *only* way to relate them to anything comparable is to read the extension taxonomy's definition linkbase. An instance-only reader gets the numbers but not their comparability.

ESMA publishes an **ESEF Conformance Suite** alongside each taxonomy version; it is the reference test set.

## SEC EDGAR (United States)

- **Format**: Inline XBRL, embedded in the 10-K/10-Q/20-F/40-F/8-K/6-K HTML. XBRL has been required since 2009; inline since roughly 2019-2021 depending on filer size.
- **Base taxonomies**: `us-gaap`, `ifrs-full`, `srt` (SEC Reporting Taxonomy), and `dei` (Document and Entity Information). `dei` is small but mandatory — it carries the filer identity and period metadata.
- **Entity identifier**: scheme `http://www.sec.gov/CIK`, value the 10-digit zero-padded CIK. The filing must also report `dei:EntityCentralIndexKey` with the matching value.
- **Extensions**: permitted and common.
- **Filing rules**: the EDGAR Filer Manual and the *EDGAR XBRL Guide*, including the concept of a "required context" that certain entity-level facts must use.

### The APIs

The SEC exposes extracted XBRL data as JSON, with no authentication:

| Endpoint | Returns |
|---|---|
| `https://data.sec.gov/submissions/CIK##########.json` | filing history and entity metadata |
| `https://data.sec.gov/api/xbrl/companyconcept/CIK##########/us-gaap/AccountsPayableCurrent.json` | every reported value of one concept for one filer, grouped by unit |
| `https://data.sec.gov/api/xbrl/companyfacts/CIK##########.json` | every non-custom fact the filer has ever reported |
| `https://data.sec.gov/api/xbrl/frames/us-gaap/AccountsPayableCurrent/USD/CY2019Q1I.json` | one fact per reporting entity for a concept in a calendar period |

Important caveats:

- These APIs **only include facts on non-custom taxonomies** (`us-gaap`, `ifrs-full`, `dei`, `srt`) that apply to the whole entity. Extension concepts and dimensionally qualified facts are absent. This is a feature for comparability and a trap if you assume completeness.
- Units with a denominator are spelled `USD-per-shares`. The default unit is `pure`.
- Frame periods: `CY####` (annual, 365 ± 30 days), `CY####Q#` (quarterly, 91 ± 30 days), `CY####Q#I` (instantaneous). Frames align filer-specific fiscal calendars onto calendar quarters, so start and end dates vary within a frame.
- No CORS. A `User-Agent` header identifying you (with contact details) is required by the SEC's access policy; requests without one are refused.
- Bulk downloads, rebuilt nightly around 03:00 ET: `https://www.sec.gov/Archives/edgar/daily-index/xbrl/companyfacts.zip` and `.../bulkdata/submissions.zip`. Use these rather than crawling.

## Denmark

The Danish Business Authority (Erhvervsstyrelsen / DCCA) has accepted annual reports as XBRL since 2009 — one of the longest-running mandates anywhere, which means the historical corpus spans every era of the standard.

- **Taxonomy namespaces**: all under `http://xbrl.dcca.dk/…`, split by the part of the report they cover — `fsa` (the financial statement line items), `gsd` (general company and reporting-period data), `cmn` (shared elements), `mrv` (management's review: activities, key figures, subsequent events), `sob` (the management and board statements approving the report), `arr` (the auditor's report), `dst` (Statistics Denmark data).
- **Entity identifier**: scheme `http://www.dcca.dk/cvr`, value the CVR number.
- **Frameworks**: the ÅRL taxonomy for reports under Danish accounting law, the IFRS-DK taxonomy for IFRS reporters, and from financial year 2025 the Finanstilsynet DKFIN taxonomy for financial undertakings.
- **Format**: XBRL instances historically; iXBRL required for all non-financial companies from January 2025.
- **Validation**: business rules are published separately, and recent taxonomy versions embed controls in the taxonomy itself. Arelle's ESEF plugin supports a `DK` authority for the Danish variations.

Because the corpus is old, Danish filings are an excellent stress test for a reader: you will meet default-namespace instances, `precision` instead of `decimals`, custom `thousandDKK` unit measures, both `segment` and `scenario` dimensions, non-ASCII names, and the same taxonomy bound to single-letter prefixes in files produced by different vendors.

## United Kingdom

Companies House and HMRC require iXBRL accounts and tax computations, using the UK taxonomies (FRS 101/102, IFRS, and the Detailed Profit and Loss taxonomy). Arelle has an HMRC validation plugin. The UK mandate was an early large-scale iXBRL deployment, and the format's design reflects that origin — the worked examples in the Inline XBRL specification itself use UK taxonomy concepts and GBP.

## Where to get taxonomies

- **<https://taxonomies.xbrl.org>** — XBRL International's registry of published taxonomies, with versions and status. Start here.
- **IFRS** — <https://www.ifrs.org/issued-standards/ifrs-taxonomy/>, published annually as a package.
- **US GAAP / SEC** — <https://xbrl.fasb.org> and <https://www.sec.gov/info/edgar/edgartaxonomies.shtml>.
- **ESEF** — ESMA publishes the taxonomy files and conformance suite per year.
- **Denmark** — Erhvervsstyrelsen publishes current and historical taxonomies.

Always prefer the **taxonomy package** ZIP over crawling the published URLs. The package includes the `catalog.xml` rewrites that make offline resolution work, and it pins a version.

## Tooling

**[Arelle](https://arelle.org)** ([GitHub](https://github.com/Arelle/Arelle), `pip install arelle-release`) is the reference open-source XBRL processor and is effectively the only complete one. Python, with a GUI, a CLI, a Python API, and a web service. It supports XBRL 2.1, Dimensions, Formula, Inline XBRL 1.1, Taxonomy Packages, the Units Registry, and xBRL-JSON/CSV.

Useful things it does that you should not reimplement:

- Full DTS discovery and resolution, with taxonomy package support.
- Inline XBRL extraction to a target document.
- Conversion to xBRL-JSON and xBRL-CSV.
- Formula evaluation.
- Programme-specific validation via plugins — `validate/ESEF`, EDGAR, HMRC.

```
python arelleCmdLine.py --plugin validate/ESEF --disclosureSystem esef-2023 \
  --package esef_taxonomy.zip --validate --file report.zip --logFile out.json
```

Disclosure systems are named `esef-YYYY` (annual consolidated) and `esef-unconsolidated-YYYY`. `--esefAuthority` selects national variations (`DK`, `UKFRC`, and others). `--logFile` takes `.xml`, `.json`, or text.

**[ixbrl-viewer](https://github.com/Arelle/ixbrl-viewer)** is an Arelle plugin that rewrites an iXBRL document into a self-contained HTML page where a reader can click any tagged number and see its concept, context, dimensions, and accuracy. It is the fastest way to understand an unfamiliar filing, and worth reaching for before writing any parsing code.

**Other languages.** There is no mature XBRL library for Go, and the ones that exist for JavaScript and Java are mostly partial readers. The realistic split is: write your own instance/iXBRL reader in your own language (very tractable, a few hundred to a couple of thousand lines), and shell out to Arelle for validation, DTS resolution, and format conversion.

**Conformance suites** are the real measure of a reader. XBRL 2.1, Dimensions, Inline XBRL 1.1, Formula, Table Linkbase, and the Units Registry each ship one, downloadable from <https://specifications.xbrl.org>. ESMA ships an ESEF suite. Running even a subset against a partial implementation finds bugs that no amount of real filings will.
