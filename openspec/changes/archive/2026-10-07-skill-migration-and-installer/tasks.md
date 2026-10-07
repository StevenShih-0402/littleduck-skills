## 1. Migrate gen-html skill

- [x] 1.1 Copy `~/tao_rui_projects/ignsw_bk_monorepo/.claude/skills/gen-html/{SKILL.md,template.html}` into `.claude/skills/gen-html/`
- [x] 1.2 Verify the migrated `SKILL.md` and `template.html` match the source content
- [x] 1.3 Confirm the full skill set in `.claude/skills/` now covers the issue/openspec series plus gen-html

## 2. Build the install/update script

- [x] 2.1 Create `install.sh` at repo root that resolves its own repo location and an optional target-project path (default `$PWD`)
- [x] 2.2 Create target dirs with `mkdir -p` and copy contents of `.claude/skills/`, `.claude/commands/`, and `linear/` into the target (copy contents, not the dir into itself, to avoid nested copies)
- [x] 2.3 Prefer `rsync` when available, fall back to `cp -R`; echo the resolved target and a summary of what was installed; exit non-zero on failure
- [x] 2.4 Make `install.sh` executable (`chmod +x`)

## 3. Verify idempotency

- [x] 3.1 Run `install.sh` against a throwaway temp directory; confirm skills, commands, and linear templates land in the right places
- [x] 3.2 Re-run against the same target; confirm files are updated in place with no duplicate/nested copies and a success exit code

## 4. Document

- [x] 4.1 Add a README section with the one-line install/update invocation and the list of installed assets (skills, commands, linear templates)
