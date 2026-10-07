## Why

The reusable Claude Code skills currently live scattered in `~/tao_rui_projects/ignsw_bk_monorepo`, tying them to one project. This repo (`littleduck-skills`) is meant to be the single source of truth for those skills, but the `gen-html` skill has not been migrated yet, and there is no supported way for *other* projects to pull these skills into their own `.claude/` directory or keep them up to date. SDP-67 asks to consolidate the skills here and give external projects a repeatable install/update command.

## What Changes

- Migrate the `gen-html` skill (`SKILL.md` + `template.html`) from the source monorepo into `.claude/skills/gen-html/`. (The `/issue-*` series and `openspec-*` skills already live in this repo; only `gen-html` is missing.)
- Add a repeatable **install/update command** (shell script invoked from an external project) that copies/syncs this repo's distributable assets — `.claude/skills/`, `.claude/commands/`, and the `linear/` templates — into the calling project's `.claude/` (and project root for `linear/`).
- The installer must be **idempotent**: running it again updates existing skills in place rather than duplicating or erroring.
- Document how an external project invokes the installer (one-line usage) and what gets installed/updated.
- Prepare the repo for the eventual GitHub push to `git@github.com:StevenShih-0402/littleduck-skills.git` (actual `git init` / push is handled downstream by `issue-solver`, not in this change).

## Capabilities

### New Capabilities
- `gen-html-skill`: the `gen-html` skill, migrated into this repo so projects that install from here get generative HTML diagram/flowchart generation.
- `skill-installer`: a repeatable, idempotent install/update command that syncs this repo's skills, commands, and `linear/` templates into an external project.

### Modified Capabilities
<!-- None: this repo has no existing specs; all capabilities are new. -->

## Impact

- New file tree: `.claude/skills/gen-html/{SKILL.md,template.html}`.
- New installer script (e.g. `install.sh` at repo root) plus usage docs (README section).
- Affects any external project that opts in by running the installer — it writes into that project's `.claude/skills/`, `.claude/commands/`, and root `linear/`.
- No changes to the already-present `issue-*` / `openspec-*` skills.
- Downstream (`issue-solver`): repo becomes a git repository and is pushed to the GitHub remote above.
