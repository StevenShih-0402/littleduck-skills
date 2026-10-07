# skill-installer Specification

## Purpose
TBD - created by archiving change skill-migration-and-installer. Update Purpose after archive.
## Requirements
### Requirement: External projects can install skills via a command

The repository SHALL provide a single install/update command (a shell script) that an external project can run to copy this repo's distributable assets into that project. The command MUST install the `.claude/skills/` directory, the `.claude/commands/` directory, and the root `linear/` templates into the target project's corresponding locations.

#### Scenario: Fresh install into a project without the skills

- **WHEN** the command is run from (or targeted at) a project that has no `.claude/skills/` from this repo
- **THEN** the project's `.claude/skills/`, `.claude/commands/`, and root `linear/` are created and populated with this repo's skills, commands, and templates
- **AND** the command exits with a success status and prints what was installed

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

The repository SHALL document how an external project invokes the installer, including a one-line usage example and the list of what gets installed or updated.

#### Scenario: Usage documented in the repo

- **WHEN** a user reads the repo's README (or equivalent docs)
- **THEN** they find the install/update command invocation and a description of the installed assets (skills, commands, linear templates)

