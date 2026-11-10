# issue-architect-skill Specification

## Purpose
提供多 Agent 流程第一棒（architect）的通用 skill：把 Linear issue 轉成前後端以同一個 change-id 建立的 OpenSpec 提案、API 契約草稿與交接檔，並回填 Linear 分析；不寫程式碼、不問 user。

## Requirements

### Requirement: Inputs come from the orchestrator and are never guessed

`issue-architect` SHALL take the primary issue, sub-issues, code, label, branch, change-id, affected repos and worktree paths from the dispatching prompt, and MUST stop and report when any is missing. It MUST NOT ask the user directly; anything needing a user decision SHALL be returned as an open question.

#### Scenario: Missing worktree path

- **WHEN** the prompt lists `repos: backend, frontend` but gives only the backend worktree path
- **THEN** the skill stops and reports the missing parameter without creating any change directory

#### Scenario: Ambiguous requirement

- **WHEN** the issue does not state which existing endpoint should change
- **THEN** the skill returns the question in its open-questions list instead of writing an assumption into the proposal

### Requirement: One change-id, one change directory per affected repo

For each affected repo the skill SHALL create `openspec/changes/<change-id>/` at the worktree root with the same lowercase change-id, writing artifacts from `openspec instructions` rather than invoking `/opsx:propose`. Each change SHALL contain `proposal.md`, `design.md`, `specs/`, `tasks.md`, `openapi.yaml`, `handoff.md` and `.linear.md`, and `openspec status` SHALL report the artifacts complete.

#### Scenario: Full-stack issue

- **WHEN** `repos` is `backend, frontend`
- **THEN** both worktrees contain `openspec/changes/<change-id>/` with all seven items
- **AND** the frontend `openapi.yaml` is identical to the backend draft

#### Scenario: Issue without API change

- **WHEN** the issue changes no endpoint
- **THEN** `openapi.yaml` still exists with `paths: {}` and states in `info.description` that the API is unchanged

### Requirement: Tasks are tagged by side and design carries diagrams

Every task line SHALL start with `[BE]` or `[FE]`; the backend `tasks.md` holds only `[BE]` items and the frontend only `[FE]`, each pointing to the other side's file, with parallelisable blocks marked. `design.md` SHALL contain at least one data-flow `flowchart` and one front/back `sequenceDiagram` drawn after loading `draw-mermaid`; a single-side change MAY omit the sequence diagram only when `design.md` states why.

#### Scenario: Untagged task

- **WHEN** the skill drafts a task without a side tag
- **THEN** it is not written that way; every line in both `tasks.md` files begins with its tag

### Requirement: Breaking API changes are proposed as a new version

When analysis finds the requested change is breaking under the API compatibility rules of the project's `CLAUDE.md`, the proposal SHALL keep the existing endpoint and add a new version-bumped endpoint rather than modifying it in place.

#### Scenario: Response field renamed

- **WHEN** the issue asks to rename a field in an existing `api/v1/` response
- **THEN** the proposal and `openapi.yaml` add an `api/v2/` endpoint and leave `api/v1/` unchanged

### Requirement: Handoff files and Linear write-back

The skill SHALL copy the team-hq `openspec/handoff-template.md` into each change with stage `proposal` and an architect section, and write an identical `.linear.md` (the `issue-reader` fields plus `repos`) in each change. It SHALL write the analysis back to Linear as `issue-reader` does, with backend and frontend decisions, and move the issues to In Progress without touching other fields.

#### Scenario: Proposal finished

- **WHEN** the skill completes
- **THEN** both `handoff.md` files show stage `proposal` and both `.linear.md` files are identical
- **AND** the Linear issue is In Progress with an analysis section naming the change-id

### Requirement: Architect writes only proposal files

The skill MUST NOT edit code, commit, push, or create branches or worktrees; its writes SHALL stay under `openspec/`.

#### Scenario: Report after run

- **WHEN** the skill finishes
- **THEN** `git status` in each worktree shows changes only under `openspec/changes/<change-id>/` and no new commit exists

### Requirement: Design lists change-specific run verification points

Each side's `design.md` SHALL contain a `## 執行驗證觀察點` section listing observation points that show this change works while the product runs, written in the same format as the repo's `CLAUDE.md` run verification section: a command with its expected output, or a screenshot command with the expected screen. Points SHALL cover only this change's behavior, not repeat the repo's own points.

#### Scenario: Change with observable behavior

- **WHEN** the change adds or alters behavior visible through a command, an HTTP response, or a page
- **THEN** that side's `design.md` lists at least one observation point for it under `## 執行驗證觀察點`

#### Scenario: Nothing observable at run time

- **WHEN** the change has no behavior that can be observed by running the product (for example, documentation only)
- **THEN** the section says 「無」 and gives the reason

#### Scenario: Repo has no run verification setup

- **WHEN** the repo's `CLAUDE.md` has no run verification section
- **THEN** the skill still writes the section, notes that the points will be skipped until the repo adds a start command, and lists this as an open question in its report

### Requirement: Design designates mutation-test targets

Each side's `design.md` SHALL contain a `## 變異測試目標` section naming the change's critical modules or paths whose test effectiveness must be verified, scoped to the change rather than the whole project, and SHALL tag each `tasks.md` task that implements such a module.

#### Scenario: Change touches critical logic

- **WHEN** the change adds or alters a permission check or a state machine
- **THEN** that side's `design.md` lists the module or path under `## 變異測試目標`
- **AND** the implementing `tasks.md` task names it as a mutation-test target

#### Scenario: Change has no critical logic

- **WHEN** the change touches no permission, state-machine, or similarly critical logic
- **THEN** the `## 變異測試目標` section reads 「無」 and states why

#### Scenario: Architect does not pick the tool

- **WHEN** the architect writes the `## 變異測試目標` section
- **THEN** it names only modules or paths, not a mutation-testing tool, command, or pass threshold
