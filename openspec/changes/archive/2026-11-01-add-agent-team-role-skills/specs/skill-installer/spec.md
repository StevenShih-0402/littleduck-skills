## MODIFIED Requirements

### Requirement: Agent team kit is installed only on explicit selection

The agent team kit SHALL be installed only when the selection is `agent-team`; `all` and single skill names MUST NOT install any kit file. Selecting `agent-team` SHALL also install the role skills listed for `agent-team` in `install.deps` (`issue-architect`, `issue-integrator`, `frontend-processor`) together with their recursively expanded dependencies, using the same overwrite-on-update behaviour as single skill installs, while kit files keep the skip-if-present behaviour.

#### Scenario: all excludes the kit

- **WHEN** the command is run with `all`
- **THEN** no agent definition templates, `ship-issue` command, write-scope hook, or workflow setup document from the kit appear in the target

#### Scenario: agent-team installs the kit

- **WHEN** the command is run with `agent-team`
- **THEN** the kit is installed into the target as a scaffold that skips files already present

#### Scenario: agent-team installs the role skills

- **WHEN** the command is run with `agent-team` against an empty directory
- **THEN** `.claude/skills/` in the target contains `issue-architect`, `issue-integrator` and `frontend-processor`
- **AND** their dependencies (`issue-reader`, `issue-processor`, `issue-solver`, the `openspec-*` skills, `draw-mermaid`, the `opsx` commands, `linear/` and `spec-sync/`) are installed
- **AND** no generic `CLAUDE.md` replaces the kit's team-hq `CLAUDE.md`

#### Scenario: Re-running agent-team updates skills but not customised kit files

- **WHEN** the target already has an edited `.claude/agents/hyuse.md` and an outdated `.claude/skills/issue-architect/SKILL.md`, and the command is run with `agent-team` again
- **THEN** `hyuse.md` is unchanged and reported as skipped
- **AND** `issue-architect/SKILL.md` is replaced by this repo's version
