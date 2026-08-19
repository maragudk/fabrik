# Diary: Add Codex sub-agent definitions

Add project-scoped Codex definitions for Fabrik's lead, builder, and writer agents while keeping their behavior aligned with the existing Claude Code definitions.

## Step 1: Design and implement semantic agent ports

**Author:** main

### Prompt Context

**Verbatim prompt:** Okay, let's add those. And we'll need to add instructions to AGENTS.md to keep the two folders in sync.

**Interpretation:** Add Codex custom-agent TOML files corresponding to all three Claude Code agents, and make semantic parity between the two platform-specific directories a repository invariant.

**Inferred intent:** Make Fabrik's lead-and-workers workflow usable from Codex without allowing the Claude and Codex agent prompts to drift apart over time.

### What I did

I used the brainstorm skill to settle the platform mapping before implementation. Markus chose semantic ports for all three agents. Builder and writer pin `gpt-5.6-terra` without a reasoning-effort override; lead inherits the parent session's model and effort. The Codex files omit Claude-only `background` and worktree-isolation metadata while preserving their behavior in the instructions.

I added `/.codex/agents/builder.toml`, `/.codex/agents/lead.toml`, and `/.codex/agents/writer.toml` with the required names, descriptions, and developer instructions. I also updated `/AGENTS.md` so every logical agent must exist in both `/agents/` and `/.codex/agents/`, with names, descriptions, responsibilities, and scope boundaries kept semantically aligned. `/README.md` now explains the two formats, and `/.claude-plugin/plugin.json` moves from `0.32.10` to `0.33.0` for the new functionality.

### Why

An empirical spawn test showed that naming generic Codex tasks `builder` and `writer` does not load Fabrik's Claude Code files. Codex requires custom agents under a project or user `.codex/agents/` directory. Semantic ports preserve the intent of each role without leaking harness-specific vocabulary into the other platform's prompt.

### What worked

The official Codex custom-agent schema maps cleanly onto the stable parts of the existing agents: name, description, model selection, and developer instructions. Keeping model selection in TOML also lets builder and writer use Terra while lead follows the interactive session's chosen model.

### What didn't work

The first patch failed before changing files with `Failed to create parent directories for /Users/maragubot/Developer/fabrik/.codex/agents/builder.toml`. Codex protects `.codex/` inside writable repositories, and the directory did not exist. Creating it explicitly with `mkdir -p /Users/maragubot/Developer/fabrik/.codex/agents` under the approved repository-metadata permission allowed subsequent `apply_patch` calls to succeed.

Codex plugins also cannot currently contribute custom agents globally. Project-scoped definitions work only in this repository, so installation into `~/.codex/agents/` remains a separate local setup step.

### What I learned

Codex already treats spawned agents as concurrent child threads, so no background flag is needed. Worktree selection belongs to the parent chat: agents share the checkout or worktree in which the session runs. This preserves the builder-sharing-lead-workspace behavior, but selecting the lead agent cannot create a new worktree by itself.

### What was tricky

The ports needed behavioral parity without literal duplication. Claude-specific model names, frontmatter, `SendMessage`, and automatic worktree isolation had to become Codex model configuration, follow-up-task language, and an explicit statement that agents remain inside the parent workspace.

### What warrants review

Compare each pair under `/agents/` and `/.codex/agents/`. Check that responsibilities and boundaries match even where the platform language differs. Validate that builder and writer pin `gpt-5.6-terra`, lead has no model override, all three TOML files parse, and a fresh Codex session discovers the custom names.

### Future work

After the version bump lands, create the corresponding `v0.33.0` release.

## Step 2: Validate discovery in a fresh Codex session

**Author:** main

### Prompt Context

**Verbatim prompt:** Yes

**Interpretation:** Proceed with the approved design, including practical validation that a newly started Codex process discovers the repository-local custom agents.

**Inferred intent:** Verify the integration through the same session-start boundary users will encounter, not only by parsing the TOML files statically.

### What I did

I compared the filenames in `/agents/` and `/.codex/agents/`, parsed all three TOML files, validated the plugin manifest with `jq`, ran `git diff --check`, and launched an ephemeral read-only `codex exec` process from the repository. The process was asked to spawn the configured builder, lead, and writer types without modifying files.

### Why

Custom-agent configuration is loaded at session start. The current conversation cannot prove that newly added files are discoverable because it began before the files existed. A fresh process tests the actual configuration boundary.

### What worked

The Claude and Codex directories both expose exactly `builder`, `lead`, and `writer`. The fresh process reported all three configured types as available and summarized their intended roles. It completed without modifying files.

### What didn't work

The first discovery command placed `--ask-for-approval never` after `codex exec`. This CLI rejected it with `error: unexpected argument '--ask-for-approval' found`. Running the approval and sandbox options before the `exec` subcommand fixed the invocation.

### What I learned

This Codex CLI documents approval options for `exec`, but its parser accepts the long approval flag reliably at the top level. The custom-agent definitions themselves loaded without additional configuration.

### What was tricky

The validation process needed network access to start a fresh model session while remaining unable to mutate the worktree. Combining an ephemeral session, read-only sandbox, and `never` approval policy provided that boundary.

### What warrants review

Confirm that a normal interactive session started in this repository shows the three custom agent types and that builder and writer run with their pinned model while lead inherits the parent session model.

### Future work

Repeat the discovery check after material changes to either platform's agent definitions.

## Step 3: Link the repository agents into the user configuration

**Author:** main

### Prompt Context

**Verbatim prompt:** Just link the whole directory

**Interpretation:** Expose the repository definitions globally through one `~/.codex/agents` directory symlink instead of separate links for each TOML file.

**Inferred intent:** Make future additions and removals propagate automatically without maintaining a second list of per-file symlinks.

### What I did

I verified that `~/.codex/agents` did not exist, then linked it to `/Users/maragubot/Developer/fabrik/.codex/agents`. I resolved the link and parsed the definitions through the home path to confirm it exposes builder, lead, and writer. Finally, I started an ephemeral read-only Codex process in `/private/tmp`; outside the repository, it discovered and spawned the global builder type through the symlink.

### Why

A directory link has less maintenance overhead and matches the repository rule that the whole Codex agent set is managed together.

### What worked

`~/.codex/agents` resolves to the repository directory, and all three definitions parse through the link. A fresh Codex process outside the repository returned `builder` after spawning that custom type, proving that Codex follows the directory symlink globally.

### What didn't work

The earlier individual-link command was interrupted before it created the directory or any files. The follow-up inspection returned `MISSING`, so replacing that approach required no cleanup and risked no existing personal definitions.

An initial `codex debug prompt-input` inspection inside the repository sandbox also failed with `Error: Operation not permitted (os error 1)`. Running it with the required permission exposed the prompt, but that output did not directly enumerate collaboration tool types. The fresh external spawn was the definitive check.

### What I learned

Linking the directory makes repository changes immediately visible to Codex sessions started anywhere on this machine.

### What was tricky

The interrupted command could have left partial state. Inspecting the exact target before creating the directory symlink prevented accidental replacement of a real directory or personal agent file.

### What warrants review

Confirm that `readlink ~/.codex/agents` still points to this checkout after moving or recreating the repository.

### Future work

If this checkout moves, recreate the symlink with the new absolute path.

## Step 4: Document Codex installation

**Author:** main

### Prompt Context

**Verbatim prompt:** Add a similar Codex subsection with concise install instructions.

**Interpretation:** Add a short Codex installation section alongside the existing Claude Code instructions.

**Inferred intent:** Make the repository's personal Codex setup reproducible without turning the README into a broad compatibility guide.

### What I did

I added a Codex subsection to `/README.md` with commands to register the Fabrik marketplace, install the plugin, and link the repository's complete agent directory into `~/.codex/agents`. The instructions also tell the user to start a new session and review the SessionStart hook with `/hooks`.

I checked the marketplace and plugin commands against the installed Codex CLI and compared the hook guidance with the current Codex documentation.

### Why

The plugin installs the Fabrik skills and hooks, while the directory symlink exposes the custom agents globally. Both steps are required to reproduce the setup validated in this session.

### What worked

The installed CLI exposes `codex plugin marketplace add` and `codex plugin add`, so the README can use direct commands without extra setup prose. The directory link also keeps future agent additions and removals synchronized automatically.

### What didn't work

During the command audit, trying the intuitive `codex plugin install` form failed with `error: unrecognized subcommand 'install'`. The correct command is `codex plugin add`, confirmed with `codex plugin add --help`.

### What I learned

Codex supports Claude-style plugin marketplace registration, but its installation verb is `add`. Custom agents remain separate from the plugin payload and need the user-level directory link. SessionStart hooks require review and trust after the plugin is installed.

### What was tricky

The section needed to stay concise while making the split installation model clear: the plugin supplies skills and hooks, and the symlink supplies custom agents.

### What warrants review

Run the documented commands from a fresh local clone and confirm that a new Codex session loads the Fabrik skills, SessionStart hook, and all three named agents.

### Future work

Keep the README commands aligned with Codex CLI changes, especially if plugins later gain native custom-agent support.
