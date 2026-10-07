## Context

`littleduck-skills` is becoming the canonical home for a set of reusable Claude Code skills (`/issue-*` series, `openspec-*`, and `gen-html`) plus the `opsx` commands and `linear/` templates. Most assets already live here; only `gen-html` still needs to be copied from `~/tao_rui_projects/ignsw_bk_monorepo/.claude/skills/gen-html/`. The missing piece is distribution: other projects currently have no supported way to pull these skills in or keep them current. This change adds the migration plus a small, dependency-free installer so any project can adopt the skills with one command and re-run it to update.

## Goals / Non-Goals

**Goals:**
- Migrate `gen-html` into `.claude/skills/gen-html/` (SKILL.md + template.html), byte-for-byte with the source.
- Provide one idempotent shell installer that syncs `.claude/skills/`, `.claude/commands/`, and `linear/` into a target project.
- Document the one-line invocation and what gets installed.

**Non-Goals:**
- `git init` and the push to the GitHub remote — handled downstream by `issue-solver`.
- A package-manager / versioned-release distribution mechanism; a copy/sync script is sufficient for now.
- Installing into anything other than a project's `.claude/` (skills, commands) and root `linear/`.

## Decisions

- **Installer is a POSIX shell script at repo root (`install.sh`).** Rationale: no runtime dependency (no Node/Python needed just to copy files); works in CI and plain shells. Alternative considered: a `/install-skill` slash command — rejected because the consumer project may not yet have the skills loaded, so a plain script they can `curl`/run is more robust.
- **Target directory resolution.** The script installs into the directory it is invoked from (the consumer project root), defaulting to `$PWD`, with an optional first argument to specify the target project path. Rationale: lets a user `cd` into their project and run it, or point at a path explicitly.
- **Copy strategy: mirror source → dest per asset root, overwriting files.** Use `cp -R` (or `rsync` when available) of `.claude/skills/`, `.claude/commands/`, and `linear/` contents into the target, creating parent dirs with `mkdir -p`. Rationale: overwrite-in-place makes the same command serve install and update.
- **Avoid nested-copy footgun.** Copy the *contents* into the destination directory (e.g. `cp -R skills/. target/.claude/skills/`) rather than the directory into itself, so re-runs never create `.claude/skills/.claude/skills/...`. This directly satisfies the idempotency scenario.
- **Source of truth for what ships.** The script derives its own location (so it copies from the repo it lives in, not from `$PWD`), making it safe to run from the consumer project.

## Risks / Trade-offs

- [Overwrite clobbers a consumer's local edits to a skill] → Installer is explicitly an install/update tool; document that it overwrites managed assets. A future `--dry-run` could preview changes if needed (out of scope here).
- [`rsync` not present on all systems] → Fall back to `cp -R`; don't hard-require `rsync`.
- [Running the script from the wrong directory installs into the wrong place] → Accept an explicit target-path argument and echo the resolved target before copying.
- [`gen-html` source drifts from the migrated copy over time] → This change migrates once; the source monorepo copy is no longer authoritative after migration (noted in the task list).

## Migration Plan

1. Copy `gen-html` from the source monorepo into `.claude/skills/gen-html/`.
2. Add `install.sh` and README usage docs.
3. Verify a dry install into a throwaway temp dir, then a re-run, to confirm idempotency.
4. (Downstream, `issue-solver`) `git init`, commit, push to the GitHub remote.
