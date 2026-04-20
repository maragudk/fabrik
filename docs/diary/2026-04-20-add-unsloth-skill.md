# Diary: Add unsloth skill

Build a skill that teaches the assistant Unsloth — the fast LoRA/QLoRA LLM fine-tuning library — with enough coverage to handle Markus's actual use case (embedding-model fine-tuning on Modal from marimo notebooks) while staying generic for other workloads (causal LLM SFT, RL, vision, TTS, export).

## Step 1: Research and draft

### Prompt Context

**Verbatim prompt:** "I'd like to create an 'unsloth' skill. Do a deep research on the docs at https://unsloth.ai/docs, then use your skill-creator skill. Work in a git worktree."

Followed by a scope clarification: "I'm primarily interested in finetuning embedding models right now. I'm using marimo notebooks, which can also run as pure Python scripts, on the Modal compute infrastructure. That's just for context, I want the skill to be somewhat generic, so I know what's possible. Re. test cases: vibe it. The audience is me."

**Interpretation:** Build a new skill in `/skills/unsloth/`, researched from the authoritative docs rather than training-set recall, with embedding fine-tuning as the headline use case but broad enough to serve as a general Unsloth reference. Skip the formal skill-creator eval loop.

**Inferred intent:** Markus is about to do real embedding fine-tuning work on Modal and wants the assistant to have trustworthy, pre-loaded context when he gets to it — fewer stale memories, fewer doc hunts mid-task. The "audience is me" signals that rigor matters more than broad approachability.

### What I did

Created worktree at `/.claude/worktrees/unsloth-skill` on branch `worktree-unsloth-skill`. Spawned a background general-purpose agent to crawl `https://unsloth.ai/docs` with a detailed brief covering 20+ topic areas (APIs, install, chat templates, LoRA hyperparams, GRPO/DPO/ORPO/KTO, vision, TTS, GGUF export, troubleshooting flags). While it ran, interviewed Markus on scope, then sent a follow-up message to the agent to specifically cover embedding fine-tuning — I wasn't confident whether Unsloth actually supported it first-class or only as a workaround.

The research agent returned a thorough 20-section report with verbatim code snippets, citing specific doc URLs. Authoritative finding: Unsloth does support embedding training first-class via `FastSentenceTransformer` (reported 1.8-3.3x speedup, ~20% less memory), plus classifier training on BERT-family models via `FastModel` with `task_type="SEQ_CLS"`.

Drafted the skill with a main `SKILL.md` (399 lines) plus six reference files:

- `/skills/unsloth/references/embeddings.md` — full BGE-M3/EmbeddingGemma/Qwen3/MiniLM recipes, target-module map per family, MNRL/TripletLoss/CachedMNRL guidance, IR evaluator pattern, reranker notes, ModernBERT classifier pathway, per-model hyperparam table.
- `/skills/unsloth/references/sft.md` — chat template strings per family, `train_on_responses_only` strings per family, dataset shapes, continued pretraining with `UnslothTrainer`, VRAM-budget table, resuming from LoRA, early stopping.
- `/skills/unsloth/references/rl.md` — GRPO preconditions, reward-function design with a full canonical set (`match_format_exactly`/`check_answer`/`check_numbers`), `GRPOConfig` values, DPO with `PatchDPOTrainer`, ORPO/KTO/SimPO/PPO notes, RLVR patterns, memory-efficient RL with `UNSLOTH_VLLM_STANDBY`.
- `/skills/unsloth/references/vision-and-tts.md` — `FastVisionModel` with the four `finetune_*` toggles, conversation shape, `UnslothVisionDataCollator` caveats (esp. `remove_unused_columns=False` and "use list comprehensions not `dataset.map`" for multi-image), TTS recipe for Orpheus, Whisper and OCR via `FastModel`.
- `/skills/unsloth/references/deployment.md` — LoRA vs merged vs GGUF save targets, full GGUF quant method list, manual llama.cpp conversion, Ollama/vLLM/SGLang/LM Studio serving, Modal deployment template with pinned versions and volume strategy.
- `/skills/unsloth/references/troubleshooting.md` — full env-flag reference, common failure modes with verbatim symptoms (loss=0, gibberish after GGUF, OOM variants, HF stall at 90-95%), dep-hell escape hatch.

Committed on the worktree branch with message "Add unsloth skill for fine-tuning LLMs and embedding models". Per `/CLAUDE.md` also added a one-line entry under "Available Skills" in `/README.md` alphabetically.

### Why

Progressive disclosure: SKILL.md should fit under 500 lines so it doesn't dominate context on every invocation; deeper material goes in references that only get read when the user is actually doing that workflow. Chose to split by workflow family (embeddings, SFT, RL, vision+TTS, deployment, troubleshooting) rather than by API because workflows are how people think about fine-tuning jobs.

Put embeddings front-and-center in SKILL.md — the short recipe is inline rather than a pointer — because Markus said it's his primary use case. The other golden paths (SFT, GRPO, vision) are similarly inline; less-common stuff (TTS, continued pretraining, Whisper) lives in references.

### What worked

Delegating the deep research to a background agent was the right call. While it crawled ~20 doc pages and returned structured output, I did the scope interview, kept my context clean, and had a much richer base to draft from than if I'd crawled myself. The mid-flight nudge about embedding-model coverage paid off — the agent's final report had a dedicated embedding section with five reference notebooks and the crucial `for_inference=True` gotcha.

Three load-bearing gotchas deserved being called out in SKILL.md's preamble because they produce *silent* failures: (1) import order — `unsloth` before `transformers`/`peft`/`trl`, because patches apply on import; (2) `use_gradient_checkpointing="unsloth"` is a magic string not a boolean; (3) `FastSentenceTransformer.from_pretrained(..., for_inference=True)` on reload or the embedding model emits wrong vectors. Putting these three rules at the top of SKILL.md means they get into the assistant's context immediately when the skill triggers.

Markus confirmed the vibe-it approach early on, which saved setting up the whole skill-creator eval scaffolding for a single-user, read-and-reference skill.

### What didn't work

Nothing significant. The research agent's scope was slightly too broad initially (I didn't explicitly call out embeddings in the first brief), caught and corrected with a `SendMessage` mid-run.

### What I learned

Unsloth's coverage has expanded well beyond decoder-only LLMs — my prior mental model was out of date. First-class support now exists for encoder/embedding models (`FastSentenceTransformer`), classification heads (`FastModel` + `AutoModelForSequenceClassification`), VLMs, and TTS. The `unsloth/` HuggingFace org also mirrors many models with pre-applied tokenizer/template fixes, so preferring `unsloth/<model>` over the upstream mirror is a small reliability win.

Reward-function design for GRPO favors many small verifiable rewards summed together, not one monolithic score. The canonical reward set (format exactly/approximately, answer match, numeric match) is a useful template to bring forward for other verifiable domains.

### What was tricky

Deciding how to carve reference files. Had to resist making one per API class (`FastLanguageModel`, `FastSentenceTransformer`, etc.) — Markus doesn't think about his work by API class, he thinks "I'm fine-tuning an embedding model" or "I'm doing RL." Workflow-oriented split won.

Keeping SKILL.md under 500 lines while fitting embeddings *and* SFT *and* RL *and* vision golden paths inline was tight. Landed at 399. The hyperparameter table went into SKILL.md rather than a reference because it's the one thing users grab-and-go with every time.

### What warrants review

- Verify the SKILL.md description triggers on embedding-specific phrasing. Test cases Markus might actually type: "fine-tune an embedding model on this dataset", "BGE-M3 LoRA", "train a retriever with hard negatives". If it under-triggers on embedding-only tasks (no Unsloth mention), tighten the description.
- The ORPO/KTO/SimPO sections in `rl.md` are pattern-described rather than verbatim-recipe'd because the upstream docs only inline DPO. If Markus hits one of those, the skill will need to fall back to "read the TRL docs" rather than hand him a working snippet — worth either testing with a real task or supplementing from the Unsloth notebooks repo later.
- Target-module lists for embedding architectures (BERT family vs Gemma/Qwen family) are correct for the architectures named. Exotic architectures (e.g. Mistral-based embedding models, if any emerge) would need their own entry.

### Future work

- If Markus runs into a concrete edge case while doing embedding fine-tuning (e.g. MatryoshkaLoss for dimensional flexibility, or multi-dataset sampling), fold the recipe back in.
- Consider a Modal-specific reference file if patterns emerge beyond the single template in `deployment.md`.
- Run the skill-creator description optimizer when there's evidence of under-triggering.

## Step 2: Ship to main and release

### Prompt Context

**Verbatim prompt:** "Just commit to main."

Followed by: "nope" (no GitHub issue to reference), "yes" (approve version bump), "yes" (clean up the worktree).

**Interpretation:** No PR flow — land directly on main. Bump version per CLAUDE.md policy (new skill = minor bump), tag, cut a GitHub release.

**Inferred intent:** This is a personal plugin, not a multi-contributor project. PRs would be ceremony. The goal is "push the button and have it live for the next session."

### What I did

Staged and committed on the worktree branch. Exited the worktree with `action: keep`. Attempted to fast-forward `main` from the worktree branch — failed because main had diverged during the session (the `modal` skill landed along with README/AGENTS.md changes documenting sub-agents and version-bump policy). Rebased `worktree-unsloth-skill` onto current `main` via `git -C <worktree> rebase main` — clean, no conflicts, the `unsloth` entry slotted alphabetically between `modal` and `worktrees`. Then fast-forwarded main and pushed.

Bumped `/.claude-plugin/plugin.json` from `0.11.0` to `0.12.0`, committed "Bump version to 0.12.0", pushed, created tag `v0.12.0`, pushed the tag, and created the GitHub release with `gh release create v0.12.0` — URL: https://github.com/maragudk/fabrik/releases/tag/v0.12.0.

Finally removed the now-merged worktree directory and deleted the `worktree-unsloth-skill` branch.

### Why

Branch had to be rebased rather than merged because this repo prefers a linear history (inferred from the log — commits are cleanly ordered single-line descriptions, no merge bubbles on the visible history). `git worktree` operations have to run inside or with `-C <worktree-path>` because the branch is pinned to the worktree — trying to `git checkout worktree-unsloth-skill` from the main repo fails with "already used by worktree at ...".

Version-bump-then-tag-then-release is the workflow CLAUDE.md documents: "Create a git tag on the version bump commit, push it, and create a release with `gh release create`". Each step gets its own commit/action so the version bump is discoverable in `git log`.

### What worked

The rebase was clean — no README merge conflict despite both branches touching the "Available Skills" list, because the alphabetical ordering meant `unsloth` slotted in cleanly after `modal` (which was what the divergent main added).

Asking about version bump separately from "just commit to main" was the right call per the saved feedback memory, even though Markus said yes immediately. The memory's reason ("ask before bumping plugin.json, tagging, and releasing after PR merges") assumes that "commit" and "release" aren't always the same beat, and that held here — there was a real decision to make about whether this was a minor or patch bump (it's minor, per CLAUDE.md's "new skill = minor" rule), and confirming kept the gate explicit.

### What didn't work

First attempt at `git checkout main && git merge --ff-only worktree-unsloth-skill && git push` failed at the shell parser with `parse error near ';&'` — zsh didn't like `&&` for some reason in this Bash tool invocation. Reran with `;` separators instead: worked. Re-flagging for future: use `;` not `&&` in Bash tool commands in this environment, or guard against it by splitting into separate tool calls.

Second failure: the fast-forward merge aborted because main had diverged (`fatal: Not possible to fast-forward, aborting`). Expected behavior — I'd been in the worktree for long enough that `modal` skill + docs changes had landed. Rebase was the clean fix.

### What I learned

The `fabrik:git` skill captures Markus's preferences cleanly — no branch-type prefixes, code identifiers in backticks, Go-style package-qualified names, asking about issue references before committing, and avoiding redundant "and updated tests" narration. The skill paid for itself here: the commit message ("Add unsloth skill for fine-tuning LLMs and embedding models") matches the repo's existing voice.

### What was tricky

The `git worktree` workflow has a specific sharp edge: the worktree branch is locked to that worktree, so you can't operate on it from the main repo checkout without `-C`. Not surprising once you think about it, but easy to stumble over when bouncing between the worktree and the main repo mid-flow.

### What warrants review

- Verify `https://github.com/maragudk/fabrik/releases/tag/v0.12.0` shows up in the remote marketplace after Claude Code's plugin cache expires. If Markus runs `/plugin update fabrik` in a fresh session, the skill should show up in the available skills list.
- Confirm the commit graph on main is still linear (no accidental merge commits from the rebase+FF flow).

### Future work

None from this shipping step. It's done.
