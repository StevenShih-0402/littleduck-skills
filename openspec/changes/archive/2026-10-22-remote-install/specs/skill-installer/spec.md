# Spec Delta

## ADDED Requirements

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

## MODIFIED Requirements

### Requirement: Installer usage is documented

The repository SHALL document how an external project invokes the installer, including the one-line remote install command, one-line usage examples for a single skill, `all`, and `agent-team`, how to pin a revision with `LITTLEDUCK_REF`, the local-clone invocation, the list of selectable names, how to enable tab completion, and how `CLAUDE.md` is delivered.

#### Scenario: Usage documented in the repo

- **WHEN** a user reads the repo's README (or equivalent docs)
- **THEN** they find the one-line remote install command with the required selection argument, the local-clone invocation, the selectable names with what each installs, the tab completion setup, and the note that an existing `CLAUDE.md` is never overwritten

#### Scenario: Documented one-liner works as written

- **WHEN** a user copies the README's one-line install command verbatim and runs it in an empty directory
- **THEN** the install succeeds
