# Diary: Add the turbopuffer skill

Distill the full turbopuffer documentation (https://turbopuffer.com/docs) into a new `turbopuffer` skill for the fabrik plugin, with Go as the primary language since Markus will use turbopuffer exclusively from Go.

## Step 1: Research the docs with parallel agents

**Author:** main

### Prompt Context

**Verbatim prompt:** "I want to make a "turbopuffer" skill. Read all the docs available at https://turbopuffer.com/docs (let me know if you can't access them), and distill the knowledge into a skill." Followed by: "You can ignore the Python stuff, I'll use it from Go."

**Interpretation:** Read all 37 turbopuffer docs pages and produce a fabrik skill in the style of the existing docs-distillation skills (modal, atproto), with Go-first examples.

**Inferred intent:** Markus plans to build search features on turbopuffer from Go and wants future sessions to have accurate, distilled knowledge on tap instead of re-fetching docs every time.

### What I did

Enumerated the doc pages from https://turbopuffer.com/docs, then fanned out four parallel research agents: fundamentals (intro, quickstart, concepts, architecture, guarantees, tradeoffs, limits, regions), features (branching, sharding, embedding, pinning, performance, backups, security), guides (vector, fts, hybrid, chunking, testing, permissions, ingestion), and API reference (api-overview, write, query, metadata, export, warm-cache, namespaces, delete-namespace, recall, plus the Go/Python client READMEs). Each returned dense per-page notes with verbatim code and limits.

### Why

37 pages is too much to fetch inline without drowning the main context; parallel extraction kept the distillation context clean and fast.

### What worked

The fundamentals agent discovered that every docs page is available as clean markdown at `https://turbopuffer.com/docs/<page>.md`, with an index at `/llms.txt` and everything in one file at `/llms-full.txt`. That recovered the verbatim Go quickstart code that the HTML rendering hides in client-side language tabs. This fact went into the skill itself as the recommended way to read reference docs.

### What didn't work

Plain WebFetch of the HTML pages silently dropped code blocks from the language-tab widgets, and a couple of extracted numbers came back without units (a branching price, embedding model dimensions). Those were flagged by the research agents and left out of the skill rather than guessed at.

### What I learned

The turbopuffer docs are Python-first; Go exists only in the quickstart and the SDK README. A Go-first skill therefore can't be assembled by quoting docs -- it needs the SDK surface verified directly.

### What was tricky

Cross-page inconsistencies: the docs' own Go snippets use `param.NewOpt(true)` without showing the import, the full quickstart example contradicts the step-by-step snippets on attribute types, and `remove_stopwords` has a different documented default in the docs page vs the SDK doc comments. The skill omits or routes around each of these.

### What warrants review

Whether the four research agents' notes were faithfully condensed -- spot-check any claim in the skill against `https://turbopuffer.com/docs/<page>.md`.

### Future work

None -- the research served this skill and is captured in it.

## Step 2: Verify the Go SDK surface and write the skill

**Author:** main

### Prompt Context

**Verbatim prompt:** (same task, continued)

**Interpretation:** Write `/skills/turbopuffer/SKILL.md` using only verified Go API names.

**Inferred intent:** A skill with plausible-but-wrong Go constructor names would be worse than no skill.

### What I did

Created a scratch Go module, fetched `github.com/turbopuffer/turbopuffer-go/v2@v2.6.0`, and enumerated the exported surface with `go doc`: all `NewFilter*`/`NewRankBy*`/`NewAggregateBy*`/`NewExpr*` constructors, `NamespaceService` methods, and the key param structs (`NamespaceWriteParams`, `NamespaceQueryParams`, `AttributeSchemaConfigParam`, `FullTextSearchConfigParam`, `LimitParam`, `NamespaceMultiQueryParams`). Then wrote `/skills/turbopuffer/SKILL.md` (modal-style single file, ~280 lines): mental model, Go client setup, write/query APIs, schema types, FTS config, hybrid search with `MultiQuery` + RRF, namespace operations, multi-tenancy and permissions patterns, a testing helper, ingestion, performance checklist, limits, and gotchas. Finally assembled every Go snippet from the skill into a probe `main.go` and ran `go build` and `go vet` against it.

### Why

The API research agent explicitly warned that constructor names beyond the README's four examples were unverified. Compiling the actual examples is the only way to be sure the skill teaches real code.

### What worked

The compile probe caught exactly one error: `res.Rows[...].ID` -- `turbopuffer.Row` is a `map[string]any`, so access is `row["id"]`. Fixed in both the probe and the skill, after which the probe built and vetted clean.

### What didn't work

`go doc <pkg> | grep '^func New'` found nothing at first because constructors are indented under their types in go doc output; grepping without the anchor fixed it. Also a cosmetic shell stumble: `=====` as an echo separator made zsh error with `==== not found` because of zsh's `=cmd` expansion.

### What I learned

`turbopuffer.Bool/Int/String` are the idiomatic optional-scalar helpers and avoid the extra `packages/param` import that the docs snippets forget -- this became a gotcha in the skill.

### What was tricky

Balancing completeness against the 500-line skill guideline. The escape hatch is the `.md` docs endpoints: the skill covers the mental model, the Go surface, and the sharp edges, and routes everything else (embedding beta, CMEK, BYOC, audit logs) to the markdown docs.

### What warrants review

Read `/skills/turbopuffer/SKILL.md` top to bottom -- especially the Limits and Gotchas sections, which condense many pages and are the most likely places for a subtle transcription error. The README entry under Available Skills should read well alongside its neighbors.

### Future work

Once real turbopuffer code exists in a project, run `/improve-skill` after the first few sessions to fold in whatever the skill got wrong or missed.

## Step 3: Ship the PR and fold in the version bump

**Author:** main

### Prompt Context

**Verbatim prompt:** "version bump as part of the PR"

**Interpretation:** Include the plugin version bump in PR #89 instead of deferring it to after the merge.

**Inferred intent:** One mergeable unit -- the skill should propagate to plugin users the moment the PR lands, without a follow-up commit.

### What I did

Committed `/skills/turbopuffer/SKILL.md`, the README entry, and this diary on branch `add-turbopuffer-skill`, pushed, and opened https://github.com/maragudk/fabrik/pull/89. On request, bumped `/.claude-plugin/plugin.json` from 0.29.1 to 0.30.0 (minor -- new skill is new functionality) in a follow-up commit on the branch, and refreshed the PR body so it no longer claimed the bump would come after merge.

### Why

The repo requires the README entry in the same commit as a new skill, and remote installs are cached by version, so the bump is what makes the skill reachable for users of the plugin.

### What worked

Checking `gh issue list` before committing: the repo has zero open issues, so the git skill's "ask about issue references and wait" step would have been an empty checkpoint, and I skipped straight to committing.

### What didn't work

Nothing failed in this step.

### What I learned

The stored preference was "ask about version bump after merge", but Markus asked for the bump inside the PR this time -- when he directs it, the bump belongs on the branch, and the PR body must be updated to match.

### What was tricky

Only the judgment call between the standing "bump after merge, ask first" feedback and the direct instruction; the direct instruction wins.

### What warrants review

That 0.30.0 is the right increment (new skill = minor per `/CLAUDE.md`), and that the PR body matches what actually shipped.

### Future work

After merge: tag `v0.30.0` on the merge commit and create the GitHub release with `gh release create`.
