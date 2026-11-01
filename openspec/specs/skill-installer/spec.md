# skill-installer Specification

## Purpose
提供單一安裝／更新指令，讓外部專案依選項（單一 skill、全部或 agent-team）把本 repo 的 skills、指令、模板與通用 CLAUDE.md 同步進專案。

## Requirements

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

### Requirement: Install command is idempotent and updates in place

Re-running the install command SHALL update already-installed skills in place without duplicating files or aborting on existing content, so the same command serves both install and update.

#### Scenario: Re-run updates existing skills

- **WHEN** the command is run a second time against a project that already has an older copy of the skills
- **THEN** existing skill files are overwritten with the current repo versions
- **AND** no duplicate or orphaned nested copies (e.g. `.claude/skills/.claude/skills/...`) are produced
- **AND** the command exits successfully

### Requirement: Installer usage is documented

The repository SHALL document how an external project invokes the installer, including the one-line remote install command, one-line usage examples for a single skill, `all`, and `agent-team`, how to pin a revision with `LITTLEDUCK_REF`, the local-clone invocation, the list of selectable names, how to enable tab completion, and how `CLAUDE.md` is delivered.

#### Scenario: Usage documented in the repo

- **WHEN** a user reads the repo's README (or equivalent docs)
- **THEN** they find the one-line remote install command with the required selection argument, the local-clone invocation, the selectable names with what each installs, the tab completion setup, and the note that an existing `CLAUDE.md` is never overwritten

#### Scenario: Documented one-liner works as written

- **WHEN** a user copies the README's one-line install command verbatim and runs it in an empty directory
- **THEN** the install succeeds

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

### Requirement: Installer runs remotely without a local clone

The installer SHALL be runnable as a single command that fetches the script from the public GitHub repository and pipes it to `sh` (e.g. `curl -fsSL <raw install.sh URL> | sh -s -- <selection> [target]`), from any directory, without the user cloning this repo first. In that mode it MUST obtain the repo's assets from GitHub and then behave exactly as a local run with the same arguments.

#### Scenario: One-line install from any directory

- **WHEN** a user in a project directory with no clone of this repo runs the one-line command with `all`
- **THEN** that directory receives the same `.claude/skills/`, `.claude/commands/`, `linear/` and `CLAUDE.md` content a local run with `all` would install
- **AND** the command exits with a success status

#### Scenario: Selection and target work the same remotely

- **WHEN** the one-line command is run with `draw-mermaid /path/to/project`
- **THEN** only the `draw-mermaid` skill (plus `CLAUDE.md` if absent) is installed into `/path/to/project`

#### Scenario: Remote run leaves no temporary files behind

- **WHEN** a remote run finishes, successfully or not
- **THEN** no downloaded archive or extracted copy of the repo remains in the target project or the temporary directory it used

#### Scenario: Local clone does not download

- **WHEN** the installer is run from a local clone of this repo
- **THEN** it uses the clone's files as the source and makes no network request

### Requirement: Remote source revision is selectable

A remote run SHALL download the `main` branch by default, and MUST download the branch or tag named by the `LITTLEDUCK_REF` environment variable when it is set. The installer MUST print which repository and revision it installs from.

#### Scenario: Default revision

- **WHEN** the one-line command is run without `LITTLEDUCK_REF`
- **THEN** the assets come from the `main` branch and the output names `main` as the source revision

#### Scenario: Pinned revision

- **WHEN** the one-line command is run with `LITTLEDUCK_REF=<tag>`
- **THEN** the assets come from that tag

### Requirement: Remote download failures abort without changes

If the remote source cannot be obtained — no download tool (`curl` or `wget`) or no `tar` available, network failure, or an unknown `LITTLEDUCK_REF` — the installer MUST print an error naming the cause and exit with a non-zero status without writing any file into the target project.

#### Scenario: Unknown ref

- **WHEN** the one-line command is run with `LITTLEDUCK_REF=no-such-branch`
- **THEN** it reports that the download failed, exits non-zero, and the target project is unchanged

#### Scenario: Missing download tool

- **WHEN** neither `curl` nor `wget` is available during a remote run
- **THEN** it reports that a download tool is required, exits non-zero, and the target project is unchanged

#### Scenario: Invalid selection is rejected without changes

- **WHEN** the one-line command is run with no selection or an unknown selection
- **THEN** it prints usage and exits non-zero without writing to the target project
