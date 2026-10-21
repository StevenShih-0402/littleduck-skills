# agent-team-kit Specification

## Purpose

提供多 Agent 開發工作流（architect / backend / frontend / integrator 四角色）的建置文件與 team-hq 資料夾骨架，讓使用者在新的協作中樞專案一次取得可直接修改的範本。

## Requirements

### Requirement: Agent team kit contents

The repository SHALL provide an agent team kit consisting of: a multi-agent workflow setup document, a team-hq `CLAUDE.md`, four agent definition templates under `.claude/agents/` (architect, backend, frontend, integrator), a `/ship-issue` orchestration command under `.claude/commands/`, and a `handoff.md` template.

#### Scenario: Kit files present in repo

- **WHEN** the repository is checked out
- **THEN** the kit source directory contains the setup document, `CLAUDE.md`, four agent definition files, `ship-issue.md`, and a `handoff.md` template

### Requirement: Kit is project-agnostic

Kit files MUST NOT contain company-specific repository names or absolute personal paths; repository locations SHALL appear as placeholders the user fills in.

#### Scenario: No company bindings remain

- **WHEN** the kit files are searched for `ignsw`, `IngenuityOA`, or `tao_rui_projects`
- **THEN** no matches are found
- **AND** repository paths appear as placeholders such as `<backend-repo>`

### Requirement: Kit does not affect this repo's own Claude Code session

Kit agent and command templates SHALL be stored outside this repo's `.claude/` directory so they are not loaded as active agents or commands when working in this repository.

#### Scenario: Working in this repo

- **WHEN** Claude Code is started at this repository's root
- **THEN** the kit's agent templates are not listed as available agents and `/ship-issue` is not an available command

### Requirement: Kit installs as a scaffold

When installed, kit files SHALL be created at the target root mirroring the team-hq layout, and any kit file that already exists in the target MUST be left unchanged and reported as skipped.

#### Scenario: Fresh scaffold

- **WHEN** the kit is installed into a directory without these files
- **THEN** `CLAUDE.md`, `.claude/agents/*.md`, `.claude/commands/ship-issue.md`, the setup document and the `handoff.md` template are created

#### Scenario: Customized files preserved

- **WHEN** the kit is installed into a directory where `.claude/agents/` already holds an edited agent file of the same name
- **THEN** that file's content is unchanged after install
- **AND** the installer output lists it as skipped
