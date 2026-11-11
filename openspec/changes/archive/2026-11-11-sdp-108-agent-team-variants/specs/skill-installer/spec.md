## ADDED Requirements

### Requirement: Removed agent-team selection points to the variants

Running the installer with the former selection `agent-team` SHALL exit non-zero without copying any file, and its message SHALL name `agent-team-fullstack` and `agent-team-single-side` as the replacements. `agent-team` MUST NOT appear in the selectable names.

#### Scenario: Old selection used

- **WHEN** the command is run with `agent-team`
- **THEN** it exits non-zero, writes nothing into the target, and tells the user to choose `agent-team-fullstack` or `agent-team-single-side`

#### Scenario: Selectable names listed

- **WHEN** the command is run with `--list`
- **THEN** the output contains `agent-team-fullstack` and `agent-team-single-side` and does not contain a line `agent-team`

### Requirement: Agent team kits are installed only on explicit selection

A kit SHALL be installed only when the selection is `agent-team-fullstack` or `agent-team-single-side`; `all` and single skill names MUST NOT install any kit file. Kit files SHALL keep the skip-if-present behaviour.

#### Scenario: all excludes the kit

- **WHEN** the command is run with `all`
- **THEN** no agent definition templates, `ship-issue` command, write-scope hook, `review.md` template, or workflow setup document from either kit appear in the target

#### Scenario: Fullstack selection installs its kit

- **WHEN** the command is run with `agent-team-fullstack`
- **THEN** the files from `agent-team-fullstack/` are installed into the target as a scaffold that skips files already present
- **AND** no file that exists only in `agent-team-single-side/` is installed

#### Scenario: Single-side selection installs its kit

- **WHEN** the command is run with `agent-team-single-side`
- **THEN** the files from `agent-team-single-side/` are installed into the target as a scaffold that skips files already present

#### Scenario: Kit selection installs the role skills

- **WHEN** the command is run with either kit selection against an empty directory
- **THEN** `.claude/skills/` in the target contains `issue-architect`, `issue-integrator`, `backend-processor`, `frontend-processor` and `custom-review`
- **AND** their dependencies (`issue-reader`, `issue-processor`, `issue-solver`, the `openspec-*` skills, `draw-mermaid`, the `opsx` commands, `linear/` and `spec-sync/`) are installed
- **AND** no generic `CLAUDE.md` replaces the kit's `CLAUDE.md`

#### Scenario: Re-running a kit selection updates skills but not customised kit files

- **WHEN** the target already has an edited `.claude/agents/hyuse.md` and an outdated `.claude/skills/issue-architect/SKILL.md`, and the command is run with the same kit selection again
- **THEN** `hyuse.md` is unchanged and reported as skipped
- **AND** `issue-architect/SKILL.md` is replaced by this repo's version

### Requirement: Kit selections install the role skills

Either kit selection SHALL also install the role skills listed for it in `install.deps` (`issue-architect`, `issue-integrator`, `backend-processor`, `frontend-processor`, `custom-review`) with their recursively expanded dependencies, overwriting older copies as single skill installs do.

#### Scenario: Role skills present after a kit install

- **WHEN** the command is run with `agent-team-single-side` against an empty directory
- **THEN** `.claude/skills/backend-processor/` and `.claude/skills/frontend-processor/` both exist

## REMOVED Requirements

### Requirement: Agent team kit is installed only on explicit selection

**Reason**: The single three-repository kit selected by `agent-team` is replaced by two kits for single-repository projects.
**Migration**: Install with `agent-team-fullstack` (one repository with backend and frontend) or `agent-team-single-side` (one repository, one side), then merge the new scaffold into existing agent definitions by hand; see "Agent team kits are installed only on explicit selection".

## MODIFIED Requirements

### Requirement: External projects can install skills via a command

The repository SHALL provide a single install/update command (a shell script) that an external project can run to copy a user-selected subset of this repo's distributable assets into that project. The selection is a required first argument: a single skill name, `all`, `agent-team-fullstack`, or `agent-team-single-side`. Installing a skill MUST also install the assets it depends on (other skills, `.claude/commands/` entries, and root `linear/` templates).

#### Scenario: Fresh install into a project without the skills

- **WHEN** the command is run with `all` from (or targeted at) a project that has no `.claude/skills/` from this repo
- **THEN** the project's `.claude/skills/`, `.claude/commands/`, and root `linear/` are created and populated with every skill, command, and template except the agent team kits
- **AND** the command exits with a success status and prints what was installed

#### Scenario: Single skill with dependencies

- **WHEN** the command is run with `issue-reader`
- **THEN** the `issue-reader` skill, the `openspec-*` skills and `opsx` commands it invokes, and the `linear/` templates it reads are installed
- **AND** unrelated skills such as `gen-html` are not installed

#### Scenario: Standalone skill

- **WHEN** the command is run with `draw-mermaid`
- **THEN** only `.claude/skills/draw-mermaid/` is installed among skills, and no `linear/` or `.claude/commands/` content is copied

#### Scenario: Target directories are created when missing

- **WHEN** the target project is missing `.claude/` or `.claude/commands/`
- **THEN** the command creates the required directories before copying, rather than failing

### Requirement: Installer usage is documented

The repository SHALL document how an external project invokes the installer, including the one-line remote install command, one-line usage examples for a single skill, `all`, `agent-team-fullstack` and `agent-team-single-side`, how to pin a revision with `LITTLEDUCK_REF`, the local-clone invocation, the list of selectable names, how to enable tab completion, and how `CLAUDE.md` is delivered.

#### Scenario: Usage documented in the repo

- **WHEN** a user reads the repo's README (or equivalent docs)
- **THEN** they find the one-line remote install command with the required selection argument, the local-clone invocation, the selectable names with what each installs (including when to choose fullstack or single-side), the tab completion setup, and the note that an existing `CLAUDE.md` is never overwritten

#### Scenario: Documented one-liner works as written

- **WHEN** a user copies the README's one-line install command verbatim and runs it in an empty directory
- **THEN** the install succeeds

### Requirement: Shared CLAUDE.md delivered without overwriting

Installing any selection other than a kit selection SHALL copy this repo's conventions `CLAUDE.md` to the target root only when the target has no `CLAUDE.md`; an existing `CLAUDE.md` MUST be left byte-for-byte unchanged and the installer SHALL print that it was skipped.

#### Scenario: Target without CLAUDE.md

- **WHEN** the command is run with `gen-html` against a project lacking `CLAUDE.md`
- **THEN** the target root gains the conventions `CLAUDE.md`

#### Scenario: Target with CLAUDE.md

- **WHEN** the command is run with `all` against a project that already has `CLAUDE.md`
- **THEN** that file is unchanged and the output states it was skipped

### Requirement: Tab completion for the selection argument

The repository SHALL provide a bash completion script that, once sourced, completes the installer's first argument with the selectable names (every installable skill, `all`, `agent-team-fullstack` and `agent-team-single-side`), derived from the repository contents rather than a hard-coded list.

#### Scenario: Completing a partial name

- **WHEN** the completion script is sourced and the user types the installer path followed by `dr` and presses Tab
- **THEN** the argument completes to `draw-mermaid`

#### Scenario: Completing a kit name

- **WHEN** the completion script is sourced and the user types the installer path followed by `agent-team-s` and presses Tab
- **THEN** the argument completes to `agent-team-single-side`

#### Scenario: New skill appears automatically

- **WHEN** a new skill directory is added under `.claude/skills/`
- **THEN** it appears among completion candidates without editing the completion script
