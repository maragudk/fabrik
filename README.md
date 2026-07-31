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

## Available Skills

- **address-code-review** - Address code review feedback by walking through comments one at a time (GitHub PR, document, or conversation)
- **atproto** - Guide for building on the AT Protocol (the "atmosphere"): authoring Lexicons, building app views, identity, repositories, XRPC, OAuth, the firehose, with Go (indigo) examples first-class
- **autoresearch** - Autonomous experiment loop that iteratively improves a measurable metric through branching, measuring, and keeping or discarding changes
- **blog-post-interview** - Interview the user about a new blog post before writing it, sharpening the angle and challenging weak claims
- **bluesky** - Guide for posting content to the Bluesky social network using the bsky terminal app
- **brainstorm** - Guide for brainstorming ideas and turning them into fully formed designs through iterative questioning
- **code-review** - Guide for making code reviews using competing agents to find architecture and implementation issues
- **code-reviewers** - Team version of `code-review`: two reviewers inspect the diff independently, challenge each other's findings, and surface only what survives scrutiny
- **dad-joke** - Tell the user a dad joke and then explain it
- **datastar** - Guide for building interactive web UIs with Datastar and gomponents-datastar
- **decisions** - Guide for recording significant architectural and design decisions in `docs/decisions.md`
- **diary** - Implementation diary that captures the narrative of your work: what changed, why, what worked, what failed, and what was tricky
- **distill-book** - Distill a long book in any format (PDF, EPUB, Markdown, HTML...) into concise, structured learnings by processing it chapter by chapter with parallel subagents, then synthesizing -- optionally into a skill
- **garden** - Autonomous project gardening: scans for maintenance issues, picks one, fixes it in a worktree with self-review, and opens a PR
- **gardeners** - Team version of `garden`: spawns a coordinated team of gardeners that each fix a different issue in parallel, sharing a task list to avoid duplicate work
- **git** - Guide for using git according to preferences (branch naming, commit messages, issue references)
- **go** - Guide for developing Go apps and modules/libraries (code style, testing, dependency injection, package structure)
- **gomponents** - Guide for working with gomponents, a pure Go HTML component library for building HTML views
- **improve-skill** - Review the current conversation for fabrik skills that could be improved and ship the improvements back as PRs (concrete fixes) or issues (fuzzy observations / redesigns)
- **marimo** - Guide for creating and working with marimo notebooks, the reactive Python notebook that stores as pure .py files
- **modal** - Guide for running Python code on Modal, the serverless compute platform for AI workloads, batch jobs, scheduled tasks, web endpoints, and sandboxed code execution
- **nanobanana** - Guide for generating and editing images using generative AI with the nanobanana CLI
- **observability** - Guide for instrumenting and operating observable systems (wide structured events, OpenTelemetry, the core analysis loop, SLOs, sampling, and observability for AI/LLMs)
- **observable-plot** - Guide for using Observable Plot, a JavaScript library for exploratory data visualization with marks, scales, and transforms
- **one-at-a-time** - Output-pacing discipline that presents one unit at a time instead of dumping a list or wall of text
- **save-web-page** - Guide for saving a web page for offline use using the [monolith CLI](https://github.com/Y2Z/monolith)
- **security-review** - Thorough security review starting from a randomly selected file, reporting a single most significant finding
- **simple-english** - Write or check technical text with the rules of ASD-STE100 Simplified Technical English (copied from [AminBlg/SimpleEnglish](https://github.com/AminBlg/SimpleEnglish))
- **spec** - Write and iterate on a project spec (`docs/spec.md`) that defines what the product is and why it exists
- **sql** - Guide for working with SQL queries, in particular for SQLite (queries, schemas, migrations)
- **turbopuffer** - Guide for building search on turbopuffer, the object-storage-native vector and full-text search engine (namespaces, schemas, BM25, hybrid search with RRF), with Go examples first-class
- **unsloth** - Guide for fine-tuning LLMs, embedding models, VLMs, and TTS models efficiently with Unsloth (LoRA/QLoRA SFT, GRPO/DPO RL, embeddings, and GGUF/Ollama/vLLM export)
- **writing-clearly-and-concisely** - Apply Strunk's *The Elements of Style* to long-form documents an audience reads: docs, READMEs, guides, specs, design docs, blog posts (not commit messages, error messages, release notes, or the diary)

## Available Sub-agents

- **builder** - Builder that takes requirements and ships code in the lead's worktree
- **lead** - Team lead that refines ideas into concrete requirements, challenges assumptions, and manages scope
- **writer** - Writer that turns briefs into clear documentation and prose, keeping heavy writing work out of the caller's context

## Available Hooks

- **SessionStart** - Shows a welcome message with the plugin version and injects `hooks/scripts/AGENTS.md`, the session context that tells the agent who you are and how you work
