# Spec Delta

## MODIFIED Requirements

### Requirement: External projects can install skills via a command

The repository SHALL provide a single install/update command (a shell script) that an external project can run to copy a user-selected subset of this repo's distributable assets into that project. The selection is a required first argument: a single skill name, `all`, or `agent-team`. Installing a skill MUST also install the assets it depends on (other skills, `.claude/commands/` entries, and root `linear/` templates).

#### Scenario: Fresh install into a project without the skills

- **WHEN** the command is run with `all` from (or targeted at) a project that has no `.claude/skills/` from this repo
- **THEN** the project's `.claude/skills/`, `.claude/commands/`, and root `linear/` are created and populated with every skill, command, and template except the agent team kit
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

The repository SHALL document how an external project invokes the installer, including one-line usage examples for a single skill, `all`, and `agent-team`, the list of selectable names, how to enable tab completion, and how `CLAUDE.md` is delivered.

#### Scenario: Usage documented in the repo

- **WHEN** a user reads the repo's README (or equivalent docs)
- **THEN** they find the install/update invocation with the required selection argument, the selectable names with what each installs, the tab completion setup, and the note that an existing `CLAUDE.md` is never overwritten

## ADDED Requirements

### Requirement: Selection argument is required and validated

The installer MUST refuse to install when the selection argument is missing or names nothing selectable, printing the usage and the list of selectable names and exiting with a non-zero status without copying any file.

#### Scenario: Missing selection

- **WHEN** the command is run with no arguments
- **THEN** it prints usage and the selectable names, and exits non-zero
- **AND** the target project is unchanged

#### Scenario: Unknown selection

- **WHEN** the command is run with `no-such-skill`
- **THEN** it reports the name as unknown, lists the selectable names, and exits non-zero without copying files

### Requirement: Agent team kit is installed only on explicit selection

The agent team kit SHALL be installed only when the selection is `agent-team`; `all` and single skill names MUST NOT install any kit file.

#### Scenario: all excludes the kit

- **WHEN** the command is run with `all`
- **THEN** no agent definition templates, `ship-issue` command, or workflow setup document from the kit appear in the target

#### Scenario: agent-team installs the kit

- **WHEN** the command is run with `agent-team`
- **THEN** the kit is installed into the target as a scaffold that skips files already present

### Requirement: Shared CLAUDE.md delivered without overwriting

Installing any selection other than `agent-team` SHALL copy this repo's conventions `CLAUDE.md` to the target root only when the target has no `CLAUDE.md`; an existing `CLAUDE.md` MUST be left byte-for-byte unchanged and the installer SHALL print that it was skipped.

#### Scenario: Target without CLAUDE.md

- **WHEN** the command is run with `gen-html` against a project lacking `CLAUDE.md`
- **THEN** the target root gains the conventions `CLAUDE.md`

#### Scenario: Target with CLAUDE.md

- **WHEN** the command is run with `all` against a project that already has `CLAUDE.md`
- **THEN** that file is unchanged and the output states it was skipped

### Requirement: Tab completion for the selection argument

The repository SHALL provide a bash completion script that, once sourced, completes the installer's first argument with the selectable names (every installable skill, `all`, and `agent-team`), derived from the repository contents rather than a hard-coded list.

#### Scenario: Completing a partial name

- **WHEN** the completion script is sourced and the user types the installer path followed by `dr` and presses Tab
- **THEN** the argument completes to `draw-mermaid`

#### Scenario: New skill appears automatically

- **WHEN** a new skill directory is added under `.claude/skills/`
- **THEN** it appears among completion candidates without editing the completion script
