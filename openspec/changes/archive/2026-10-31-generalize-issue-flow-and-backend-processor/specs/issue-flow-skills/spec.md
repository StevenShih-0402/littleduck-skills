# Spec Delta

## Purpose

定義三段式 Linear → OpenSpec 流程 skill（issue-reader / issue-processor / issue-solver）與 `linear/` 模板在任何專案安裝後都成立的通用行為。

## ADDED Requirements

### Requirement: Issue identifiers are recognized generically

The issue flow skills SHALL recognize any Linear issue identifier of the form uppercase team key, hyphen, number (e.g. `ENG-123`, `ABC2-7`) from their arguments, and MUST NOT require or assume a specific team prefix.

#### Scenario: Non-default team prefix

- **WHEN** `/issue-reader ENG-12, ENG-15` is invoked
- **THEN** both `ENG-12` and `ENG-15` are treated as issues to merge into one proposal

#### Scenario: No identifier given

- **WHEN** `/issue-reader` is invoked with arguments containing no identifier of that form
- **THEN** the skill stops before any Linear or OpenSpec call and shows the invocation format

### Requirement: Issue flow skills are project-agnostic

The issue flow skills and `linear/` templates MUST NOT contain another project's names, paths, issue prefixes, or stack-specific commands; project-specific rules (test, lint and build commands, environment limits) SHALL be taken from the target project's `CLAUDE.md` and the change's `design.md`.

#### Scenario: No leftover project bindings

- **WHEN** the issue flow skill files and `linear/` templates are searched for `SDP-`, `IGN-`, `ollama`, `ignsw`, `pants` or `tao_rui_projects`
- **THEN** no matches are found

#### Scenario: Test command not documented

- **WHEN** `issue-processor` needs to run tests and the project's `CLAUDE.md` and the change's `design.md` do not state how
- **THEN** the skill asks the user for the command instead of guessing one

### Requirement: Breaking API changes are not implemented in place

Before implementing, `issue-processor` SHALL judge whether the change is a breaking API change using the API compatibility criteria in `CLAUDE.md`. When a task reads as modifying an existing endpoint in place but the change is breaking, the skill MUST stop, report, and recommend updating the change artifacts instead of implementing the task literally.

#### Scenario: Task renames a response field in place

- **WHEN** `tasks.md` says to rename a response field of an existing `api/v1/` endpoint
- **THEN** `issue-processor` does not edit that endpoint
- **AND** it reports that the task is a breaking change and suggests adding an `api/v2/` endpoint in the artifacts

#### Scenario: Non-breaking addition

- **WHEN** `tasks.md` says to add an optional request field to an existing endpoint
- **THEN** `issue-processor` implements it in place

### Requirement: Primary issue records API consumer impact

The primary issue SHALL carry a `> ▲ 前端需注意的變動` quote block alongside `> 更動摘要`: `issue-reader` creates it as a placeholder and `issue-processor` fills it after implementation with every change affecting API consumers, or `無` when there is none. The `linear/` templates SHALL describe this block.

#### Scenario: Change with field rename

- **WHEN** `issue-processor` finishes a change that adds a new endpoint version with a renamed field
- **THEN** the primary issue's `> ▲ 前端需注意的變動` block lists the new path and the renamed field

#### Scenario: Backend-only change

- **WHEN** `issue-processor` finishes a change with no API contract impact
- **THEN** the block reads `無`

### Requirement: issue-solver runs the spec sync gate before archiving

`issue-solver` SHALL run the spec sync gate (see `spec-sync-gate`) before `/opsx:archive` and MUST NOT archive while the gate is unresolved. Any exemptions the user declares SHALL appear in the PR body, and the final report SHALL state the gate result per rule.

#### Scenario: Gate unresolved

- **WHEN** the gate reports an unsynced spec folder and the user chooses to fix the specs first
- **THEN** `issue-solver` stops without archiving, committing or creating a PR

#### Scenario: Exemption carried to PR

- **WHEN** the user declares an exemption with a reason for one spec folder
- **THEN** the created PR body lists that folder and the reason
