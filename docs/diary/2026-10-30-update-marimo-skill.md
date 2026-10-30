# Diary: Bring the marimo skill up to date with marimo 0.25.2

The `marimo` skill was written on 2026-01-23 in maragudk/skills (around marimo 0.19) and copied into fabrik unchanged. marimo is now at 0.25.2. Check the skill against https://docs.marimo.io and fix what is stale or wrong.

## Step 1: Verify every API against the docs and the installed package

**Author:** main

### Prompt Context

**Verbatim prompt:** Check that the marimo skill is up to date with https://docs.marimo.io, and fix anything that needs updating. You can check when the skill is from in git if that helps.

**Interpretation:** Audit `SKILL.md` and all 18 reference files, fix wrong content, and add the important things that are new since January.

**Inferred intent:** Make the skill trustworthy again, so agents writing marimo notebooks don't copy broken examples out of it.

### What I did

Installed marimo 0.25.2 in a scratchpad venv so every claim could be checked with `inspect.signature`, the package source, and small test notebooks, not just against the docs. The docs are available as Markdown (`https://docs.marimo.io/llms.txt` indexes `.md` versions of every page), which made them cheap to fetch.

Rewrote the stale parts of `SKILL.md` myself: the file format (`__generated_with`, `with app.setup:`, `@app.function`, a bare `return`, the `if __name__ == "__main__"` guard), install via uv and `--sandbox`, the current CLI (`marimo check`, `marimo new`, more export targets, `marimo convert` for `.md` and py:percent), an "as an agent" section (`marimo check`, `marimo edit --watch`, `marimo pair`), and the docs' best practices. The example notebook in `SKILL.md` runs, its `@app.function` imports from another script, and it passes `marimo check --strict`.

Split the reference files across five general-purpose subagents with disjoint file ownership and a shared brief: the installed package wins over the docs, verify every name and parameter, fix wrong things, add only genuinely useful new APIs, keep structure and voice. Spot-checked their main claims against the venv.

### Why

The installed package is the ground truth an agent's code will run against. The docs are good but not always right (see below), and the skill's own examples turned out to be the bigger problem.

### What worked

Verifying against the installed package caught many examples that were plausible but broken, often in ways the docs alone would not reveal:

- `mo.sql(f"SELECT * FROM {df}")` pasted the DataFrame's repr into the query; dataframes are referenced by name (`FROM df`).
- `mo.sql(..., output="native")`: `output` is a display bool, so a string is silently truthy. The result type is `marimo.App(sql_output=...)`.
- `@app.cell(name="x")` does nothing; `App.cell` deletes its `**kwargs`. Cells are named by their function name.
- Non-existent APIs and parameters: `mo.justify`, `mo.ui.nav_menu` (it is `mo.nav_menu`), `mo.audio(autoplay=...)`, `image_compare(left=, right=)`, `refresh(interval=)`, `QueryParams.items()/.update()/.pop()`.
- Several examples read a UI element's `.value` in the same cell that created it, which never updates.

### What didn't work

My regex syntax check over all Python fences flagged three snippets in `markdown.md` and `outputs.md`. They were false positives from nested backtick fences, not real errors.

### What I learned

The official docs have their own errors. `api/cli_args` shows `python notebook.py -- --lr 1e-4`, but in 0.25.2 script mode leaves `--` in `sys.argv`, and `mo.cli_args()` gets a stray `''` key. `--` is only right with `marimo edit/run/export`. The pytest guide calls the config key `reactive_test`, but the installed key is `runtime.reactive_tests`. The `persistent_cache` default `method` is `"pickle"` in the package, not what the docs describe.

### What was tricky

Deciding what to leave out. The reviewers skipped editor-only features (chart builder, SQL validate mode, cache signing) and niche parameters, so the references would not bloat.

### What warrants a second pair of eyes

- `skills/marimo/references/state.md`: the example fixes rest on reading the runtime code (callbacks run in the defining cell's context), not on a live run in the editor.
- `skills/marimo/references/cell.md`: the pytest section is from the docs plus a config-key check; pytest itself was not run.

### What should be done in the future

- Re-run this audit after the next few marimo minor releases; the API moves quickly.

### Code review instructions

- Start with `skills/marimo/SKILL.md`, then `references/sql.md`, `references/cell.md` and `references/cli-args.md`, which had the most consequential fixes.
- To validate, install `marimo==0.25.2` and check any API against `inspect.signature`, or paste an example into a notebook and run `marimo check`.

### Technical details

Spot checks run against 0.25.2: `hasattr(mo, "justify")` is False; `mo.audio` is `(src, rate=None, normalize=True)`; `image_compare` is `(before_image, after_image, value=50, direction=..., width=None, height=None)`; `"del kwargs" in inspect.getsource(mo.App.cell)` is True; `python nb.py -- --lr 0.1` gives `{'': '', 'lr': 0.1}`.
