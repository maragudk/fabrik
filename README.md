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
- **memory** - Keep agent memory in a `## Memory` section at the bottom of the project's `AGENTS.md` instead of the harness's built-in memory: when and what to save, format, pruning, and opt-in setup
- **modal** - Official Modal skill (vendored from `modal skills install`) for the Modal cloud platform: serverless compute, GPUs, batch jobs, and sandboxes, with the Modal docs bundled under `references/`
- **nanobanana** - Guide for generating and editing images using generative AI with the nanobanana CLI
- **observability** - Guide for instrumenting and operating observable systems (wide structured events, OpenTelemetry, the core analysis loop, SLOs, sampling, and observability for AI/LLMs)
- **one-at-a-time** - Output-pacing discipline that presents one unit at a time instead of dumping a list or wall of text
- **second-opinion** - Get a second opinion from another AI model (OpenAI via the [codex CLI](https://github.com/openai/codex), or Google Gemini via the agy CLI) on designs, bugs, and code
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

- **SessionStart** - Shows a welcome message, injects `hooks/scripts/AGENTS.md` (the session context that tells the agent who you are and how you work), and installs the secret-scanning git hooks
