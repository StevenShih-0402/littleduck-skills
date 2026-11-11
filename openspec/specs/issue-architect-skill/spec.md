# issue-architect-skill Specification

## Purpose
提供多 Agent 流程第一棒（architect）的通用 skill：依專案 `CLAUDE.md` 的「## agent-team 設定」（fullstack 或 single-side），把 Linear issue 轉成一份 OpenSpec 提案、API 契約草稿與交接檔，並回填 Linear 分析；不寫程式碼、不問 user。

## Requirements

### Requirement: Inputs come from the orchestrator and are never guessed

`issue-architect` SHALL take the primary issue, sub-issues, code, label, branch, change-id, affected sides and the worktree path from the dispatching prompt, and read the structure, subdirectories or side from the repository `CLAUDE.md` `## agent-team 設定`. It MUST stop and report when any is missing. It MUST NOT ask the user directly; anything needing a user decision SHALL be returned as an open question.

#### Scenario: Missing worktree path

- **WHEN** the prompt gives no worktree path
- **THEN** the skill stops and reports the missing parameter without creating any change directory

#### Scenario: Missing structure declaration

- **WHEN** the repository `CLAUDE.md` has no `## agent-team 設定` section
- **THEN** the skill stops and reports the missing declaration without creating any change directory

#### Scenario: Ambiguous requirement

- **WHEN** the issue does not state which existing endpoint should change
- **THEN** the skill returns the question in its open-questions list instead of writing an assumption into the proposal

### Requirement: One change-id, one change directory per affected repo

The skill SHALL create one `openspec/changes/<change-id>/` at the worktree root with the lowercase change-id, writing artifacts from `openspec instructions` rather than invoking `/opsx:propose`. The change SHALL contain `proposal.md`, `design.md`, `specs/`, `tasks.md`, `openapi.yaml`, `handoff.md` and `.linear.md`, and `openspec status` SHALL report the artifacts complete.

#### Scenario: Full-stack issue

- **WHEN** the structure is `fullstack` and the affected sides are backend and frontend
- **THEN** the worktree contains exactly one `openspec/changes/<change-id>/` with all seven items

#### Scenario: Issue without API change

- **WHEN** the issue changes no endpoint
- **THEN** `openapi.yaml` still exists with `paths: {}` and states in `info.description` that the API is unchanged

### Requirement: Tasks are tagged by side and design carries diagrams

Every task line SHALL start with `[BE]` or `[FE]`, all in the one `tasks.md`. In `fullstack`, `[BE]` tasks SHALL come before the `[FE]` tasks that depend on them, because developers run in that order; in `single-side`, every task SHALL carry the declared side's tag.

#### Scenario: Untagged task

- **WHEN** the skill drafts a task without a side tag
- **THEN** it is not written that way; every line in `tasks.md` begins with its tag

#### Scenario: Single-side frontend project

- **WHEN** the repository declares `結構: single-side` and `端: frontend`
- **THEN** every task in `tasks.md` begins with `[FE]`

### Requirement: Breaking API changes are proposed as a new version

When analysis finds the requested change is breaking under the API compatibility rules of the project's `CLAUDE.md`, the proposal SHALL keep the existing endpoint and add a new version-bumped endpoint rather than modifying it in place.

#### Scenario: Response field renamed

- **WHEN** the issue asks to rename a field in an existing `api/v1/` response
- **THEN** the proposal and `openapi.yaml` add an `api/v2/` endpoint and leave `api/v1/` unchanged

### Requirement: Handoff files and Linear write-back

The skill SHALL copy the repository's `openspec/handoff-template.md` into the change with stage `proposal` and an architect section, and write one `.linear.md` with the `issue-reader` fields plus `repos` listing the affected sides. It SHALL write the analysis back to Linear as `issue-reader` does, with separate backend and frontend decisions when both sides are affected, and move the issues to In Progress without touching other fields.

#### Scenario: Proposal finished

- **WHEN** the skill completes
- **THEN** `handoff.md` shows stage `proposal` and `.linear.md` lists the affected sides in `repos`
- **AND** the Linear issue is In Progress with an analysis section naming the change-id

### Requirement: Architect writes only proposal files

The skill MUST NOT edit code, commit, push, or create branches or worktrees; its writes SHALL stay under `openspec/`.

#### Scenario: Report after run

- **WHEN** the skill finishes
- **THEN** `git status` in the worktree shows changes only under `openspec/changes/<change-id>/` and no new commit exists

### Requirement: Design lists change-specific run verification points

The change's `design.md` SHALL contain a `## 執行驗證觀察點` section listing observation points that show this change works while the product runs, written in the same format as the repository `CLAUDE.md` run verification section: a command with its expected output, or a screenshot command with the expected screen. Points SHALL cover only this change's behavior, not repeat the repository's own points.

#### Scenario: Change with observable behavior

- **WHEN** the change adds or alters behavior visible through a command, an HTTP response, or a page
- **THEN** `design.md` lists at least one observation point for it under `## 執行驗證觀察點`

#### Scenario: Nothing observable at run time

- **WHEN** the change has no behavior that can be observed by running the product (for example, documentation only)
- **THEN** the section says 「無」 and gives the reason

#### Scenario: Repo has no run verification setup

- **WHEN** the repository `CLAUDE.md` has no run verification section
- **THEN** the skill still writes the section, notes that the points will be skipped until the repository adds a start command, and lists this as an open question in its report

### Requirement: Design designates mutation-test targets

The change's `design.md` SHALL contain a `## 變異測試目標` section naming the change's critical modules or paths whose test effectiveness must be verified, scoped to the change rather than the whole project, and SHALL tag each `tasks.md` task that implements such a module.

#### Scenario: Change touches critical logic

- **WHEN** the change adds or alters a permission check or a state machine
- **THEN** `design.md` lists the module or path under `## 變異測試目標`
- **AND** the implementing `tasks.md` task names it as a mutation-test target

#### Scenario: Change has no critical logic

- **WHEN** the change touches no permission, state-machine, or similarly critical logic
- **THEN** the `## 變異測試目標` section reads 「無」 and states why

#### Scenario: Architect does not pick the tool

- **WHEN** the architect writes the `## 變異測試目標` section
- **THEN** it names only modules or paths, not a mutation-testing tool, command, or pass threshold

### Requirement: Design carries data-flow and sequence diagrams

`design.md` SHALL contain at least one data-flow `flowchart` and one front/back `sequenceDiagram`, drawn after loading `draw-mermaid`; a change without front/back interaction MAY omit the sequence diagram only when `design.md` states why.

#### Scenario: Change without front/back interaction

- **WHEN** a single-side change has no front/back interaction
- **THEN** `design.md` still has a data-flow `flowchart`, and either a sequence diagram or a stated reason for omitting it
