# fabrik

<img src="logo.png" alt="Logo" width="300" align="right">

How [@maragubot](https://www.maragubot.com) and I build.

Made with ✨sparkles✨ by [maragu](https://www.maragu.dev/): independent software consulting for cloud-native Go apps & AI engineering.

[Contact me at markus@maragu.dk](mailto:markus@maragu.dk) for consulting work, or perhaps an invoice to support this project?

## Usage

**Heads up:** This plugin is tuned for how _I_ work -- it tells your AI agent your name is Markus, you prefer Go and dry humor, and you have opinions about SQLite. Unless you want your AI to treat you like a clone of me, you should **fork this repo** and customize the skills, hooks, and session context to match your own preferences. Think of this as a starting point, not a one-size-fits-all config.

### Claude Code

```shell
/plugin marketplace add maragudk/fabrik
/plugin install fabrik@maragu
```

### Codex

Run these commands from a local clone:

```shell
codex plugin marketplace add maragudk/fabrik
codex plugin add fabrik@maragu
ln -s "$(pwd)/.codex/agents" ~/.codex/agents
```

Start a new session, then use `/hooks` to review and trust the SessionStart hook.

### Antigravity

```shell
agy plugin install https://github.com/maragudk/fabrik
```

Re-run the command to update.

To enable the custom agents (`lead`, `builder`, `writer`) globally and override the plugin's Claude Code `lead` definition, link `.antigravity/agents` from a local clone (ensure `~/.gemini/config/agents` does not already exist so `ln -s` does not nest inside it, or copy `.antigravity/agents/*.md` into `~/.gemini/config/agents/`):

```shell
ln -s "$(pwd)/.antigravity/agents" ~/.gemini/config/agents
```

## Available Skills

- **ableton-live** - Guide for making music in Ableton Live 12 on macOS: Session vs Arrangement, warping, MIDI editing and MIDI Tools, routing, automation, Racks, every stock device and instrument, Push, sync, and shortcuts (distilled from the Live 12 reference manual)
- **accomplishments** - Extract accomplishments from new diary entries into docs/accomplishments.md as one-line reflections blending self-appraisal with Markus's appreciation; the session-start hook injects the five most recent at startup
- **address-code-review** - Address code review feedback by walking through comments one at a time (GitHub PR, document, or conversation)
- **atproto** - Guide for building on the AT Protocol (the "atmosphere"): authoring Lexicons, building app views, identity, repositories, XRPC, OAuth, the firehose, with Go (indigo) examples first-class
- **bluesky** - Guide for posting content to the Bluesky social network using the bsky terminal app
- **code-review** - Guide for making code reviews using competing agents to find architecture and implementation issues
- **dad-joke** - Tell the user a dad joke and then explain it
- **datastar** - Guide for building interactive web UIs with Datastar and gomponents-datastar
- **define-task** - Define a task before work starts: interview the user, agree on a goal, and agree on how to verify the goal is met
- **diary** - Implementation diary that captures the narrative of your work: what changed, why, what worked, what failed, and what was tricky
- **distill-book** - Distill a long book in any format (PDF, EPUB, Markdown, HTML...) into concise, structured learnings by processing it chapter by chapter with parallel subagents, then synthesizing -- optionally into a skill
- **garden** - Autonomous project gardening: scans for maintenance issues, picks one, fixes it in a worktree with self-review, and opens a PR
- **gardeners** - Team version of `garden`: spawns a coordinated team of gardeners that each fix a different issue in parallel, sharing a task list to avoid duplicate work
- **git** - Guide for using git according to preferences (commit messages, issue references, pull requests)
- **go** - Guide for developing Go apps and modules/libraries (code style, testing, dependency injection, package structure)
- **improve-skill** - Review the current conversation for fabrik skills that could be improved and ship the improvements back as PRs (concrete fixes) or issues (fuzzy observations / redesigns)
- **marimo** - Guide for creating and working with marimo notebooks, the reactive Python notebook that stores as pure .py files
- **modal** - Official Modal skill (vendored from `modal skills install`) for the Modal cloud platform: serverless compute, GPUs, batch jobs, and sandboxes, with the Modal docs bundled under `references/`
- **nanobanana** - Guide for generating and editing images using generative AI with the nanobanana CLI
- **observability** - Guide for instrumenting and operating observable systems (wide structured events, OpenTelemetry, the core analysis loop, SLOs, sampling, and observability for AI/LLMs)
- **one-at-a-time** - Output-pacing discipline that presents one unit at a time instead of dumping a list or wall of text
- **save-web-page** - Guide for saving a web page for offline use using the [monolith CLI](https://github.com/Y2Z/monolith)
- **second-opinion** - Get a second opinion from another AI model (OpenAI via the [codex CLI](https://github.com/openai/codex), or Google Gemini via the agy CLI) on designs, bugs, and code
- **simple-english** - Write or check technical text with the rules of ASD-STE100 Simplified Technical English (copied from [AminBlg/SimpleEnglish](https://github.com/AminBlg/SimpleEnglish))
- **sql** - Guide for working with SQL queries, in particular for SQLite (queries, schemas, migrations)
- **turbopuffer** - Guide for building search on turbopuffer, the object-storage-native vector and full-text search engine (namespaces, schemas, BM25, hybrid search with RRF), with Go examples first-class
- **writing-clearly-and-concisely** - Apply Strunk's *The Elements of Style* to long-form documents an audience reads: docs, READMEs, guides, specs, design docs, blog posts (not commit messages, error messages, release notes, or the diary)
- **xbrl** - Guide for working with XBRL, the digital business reporting standard: instances, Inline XBRL, taxonomies and linkbases, dimensions, the Open Information Model, and the filing programmes (ESEF, SEC EDGAR, Denmark)

## Available Sub-agents

Sub-agents have Claude Code definitions in `agents/`, semantic Codex ports in `.codex/agents/`, and semantic Antigravity ports in `.antigravity/agents/`.

- **builder** - Builder that takes requirements and ships code in the lead's worktree, or its own when running in parallel
- **lead** - Lead that refines ideas into concrete requirements, challenges assumptions, and manages scope
- **writer** - Writer that turns briefs into clear documentation and prose, keeping heavy writing work out of the caller's context

## Available Hooks

- **SessionStart** - Shows a welcome message, injects `hooks/scripts/AGENTS.md` (the session context that tells the agent who you are and how you work), and installs the secret-scanning git hooks described below

### Secret scanning

A dependency-free bash pre-commit hook blocks commits that contain secrets. It scans the added lines of the staged diff for:

- Anthropic API keys (`sk-ant-...`, including admin keys and OAuth tokens)
- OpenAI API keys (`sk-proj-`, `sk-svcacct-`, `sk-admin-`, and the legacy `sk-` format)
- AWS access key IDs (`AKIA...`, `ASIA...`) and AWS secret access keys (only as the value of a name like `aws_secret_access_key` on the same line)
- Google API keys (`AIza...`)
- Tigris access key IDs (`tid_...`) and secret access keys (`tsec_...`)

It also blocks a commit that adds a file named exactly `.env`; `.env.example`, `.env.local`, and the like pass. Findings are printed redacted.

The hook covers every repository on the machine. At session start, fabrik copies its git hooks to `~/.config/fabrik/git-hooks/` (or `$XDG_CONFIG_HOME/fabrik/git-hooks/`) and, if `core.hooksPath` is unset, points the global `core.hooksPath` there. To opt out, set `core.hooksPath` to another directory in the global git config, a file it includes, or the system config: fabrik leaves it alone and warns at session start that scanning is inactive.

A global `core.hooksPath` makes git ignore a repository's own `.git/hooks`, so fabrik's hooks run the repository's client-side hook of the same name. The pre-commit hook runs it after the scan passes. git-lfs cannot install its hooks while `core.hooksPath` is set, so in a Git LFS repository with no hook of its own, the pre-push, post-checkout, post-commit, and post-merge hooks run `git lfs <hook>` in its place.

Known gaps:

- `git commit --no-verify` skips the scan.
- A repository that sets its own `core.hooksPath` (as husky v9 does) overrides the global one, so its commits go unscanned.
- Clean merges, cherry-picks, rebases, and `git am` don't run pre-commit, so they go unscanned. Concluding a conflicted merge with `git commit` does scan everything incoming from the other branch.
- Files git treats as binary, including those marked `-diff` or `binary` in `.gitattributes`, are not scanned.
- A repository's own `reference-transaction`, `post-index-change`, and `push-to-checkout` hooks stop running. fabrik deliberately leaves them unchained: the first two fire so often that chaining them made git many times slower, and the mere presence of the third changes what git does.
- Server-side hooks (`pre-receive`, `update`, `post-receive`, `post-update`) stop running too, which affects push-to-deploy repositories on the machine.
- `git lfs install` reports "Hook already exists", and the pre-commit framework refuses to install, while `core.hooksPath` is set.

Run the tests with `bash hooks/test/test-git-hooks.sh`.
