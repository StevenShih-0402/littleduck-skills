# Spec Delta

## Purpose

提供多 Agent 流程中後端實作棒的通用 skill：依 OpenSpec 交接資料在後端 worktree 逐項實作、可中斷接續，並附帶編輯後自動 lint 的 hook。

## ADDED Requirements

### Requirement: Inputs are verified before any implementation

`backend-processor` SHALL read the change's `proposal.md`, `design.md`, `openapi.yaml`, `tasks.md`, `handoff.md` and `specs/` from the backend worktree, and MUST stop and report without editing code when any is missing or `handoff.md` has no `## 狀態` block. When `.linear.md` exists its `branch` MUST match the current branch; otherwise the current branch MUST NOT be the default branch.

#### Scenario: Missing openapi draft

- **WHEN** the change directory has no `openapi.yaml`
- **THEN** the skill reports the missing file and makes no code change

#### Scenario: No issue handoff file

- **WHEN** the change has no `.linear.md` and the worktree is on a non-default branch
- **THEN** the skill proceeds and takes the issue identifier from the change-id prefix

#### Scenario: Old handoff without status block

- **WHEN** `handoff.md` lacks a `## 狀態` block
- **THEN** the skill stops and tells the user to add it following the current `handoff-template.md`

### Requirement: Work resumes safely after interruption

On start, the skill SHALL stop when the worktree has uncommitted changes (listing them and flagging migration files) or the branch is behind or diverged from its remote; it SHALL push first when only ahead. It SHALL re-run the verification of the last checked `[BE]` task and uncheck it on failure. It MUST NOT stash, reset, discard or commit leftover changes on its own.

#### Scenario: Half-written migration left behind

- **WHEN** the worktree has an uncommitted file under a `migrations/` directory
- **THEN** the skill stops, lists the file marked as a migration, and leaves it untouched

#### Scenario: Last task no longer passes

- **WHEN** the last checked `[BE]` task's verification fails on restart
- **THEN** that task is unchecked, the failure is written to the status block's pause reason, and work restarts from that task

#### Scenario: Interrupted during wrap-up

- **WHEN** all `[BE]` tasks are checked but the status block's stage is not `integrating`
- **THEN** the skill resumes from testing and hand-off without re-implementing tasks

### Requirement: Each task is committed and pushed on its own

For each `[BE]` task the skill SHALL verify, check it in `tasks.md` with a one-line note, update the status block, stage only the listed paths, commit as `wip(<ISSUE-ID>): <task number> <summary>`, and push. A model change and its migration MUST be in the same commit. The skill MUST NOT use `git add -A`/`git add .`, `--no-verify`, or force push.

#### Scenario: Task completed

- **WHEN** task 2.1 passes its verification
- **THEN** a commit `wip(ENG-200): 2.1 …` containing the task's files, `tasks.md` and `handoff.md` is pushed
- **AND** `git status --porcelain` is empty afterwards

#### Scenario: Push rejected

- **WHEN** the push fails
- **THEN** the skill stops, records "commit 尚未推送" as the pause reason, and does not force push

### Requirement: Stack-specific commands come from the project

Test, lint, schema generation and migration commands SHALL be taken from the project's `CLAUDE.md` or the change's `design.md`; when absent the skill MUST ask the user. When migrations are added it SHALL verify they apply forward and backward.

#### Scenario: Project documents a containerized test command

- **WHEN** the project's `CLAUDE.md` states tests run inside a container with a given command
- **THEN** the skill runs tests with that command rather than a host `pytest`

### Requirement: OpenAPI is finalized from the implementation

Before hand-off the skill SHALL make `openapi.yaml` match the implemented API, note changed fields in `handoff.md`, copy it to the frontend change directory when the change involves a frontend, and commit only that one file in the frontend worktree.

#### Scenario: Draft differs from implementation

- **WHEN** the implemented response field name differs from the draft
- **THEN** `openapi.yaml` is updated to the implementation and `handoff.md` names the changed field
- **AND** the frontend copy is identical to the backend file

### Requirement: Specs are synced within the task

When `openspec/spec-sync.yaml` exists, a task that changes code matched by a rule SHALL, in the same task, write or update the change's delta for a `capability` target or update the document itself for a `spec_dir` target. It MUST NOT edit main specs under `openspec/specs/` directly. When the rule's exemption description applies, it SHALL instead write one exemption line per target in `handoff.md`'s backend section for the final gate to confirm.

#### Scenario: Capability code changed

- **WHEN** a task edits a path mapped to capability `apps/billing`
- **THEN** the same task's commit includes `openspec/changes/<change-id>/specs/apps/billing/spec.md`
- **AND** `openspec/specs/apps/billing/spec.md` is not modified

#### Scenario: Deployment file changed

- **WHEN** a task edits a path mapped to a `spec_dir` target
- **THEN** the same task's commit includes the mapped document, or `handoff.md` contains an exemption line for that target

### Requirement: Hand-off leaves a clean, synced state

The skill SHALL finish by appending a backend section to `handoff.md`, setting the status block's stage to `integrating`, and pushing so the worktree is clean and not ahead. It MUST NOT open a PR, archive, or edit `proposal.md`.

#### Scenario: Normal completion

- **WHEN** all `[BE]` tasks are done and tests pass
- **THEN** the stage is `integrating`, no PR exists for the branch from this skill, and the change is not archived

### Requirement: Post-edit lint hook

The skill SHALL ship a PostToolUse hook script that lints only the single edited `.py` file within its repository, using `LITTLEDUCK_LINT_CMD` when set, otherwise an auto-detected linter, and does nothing when none is found. It MUST exit 2 with the lint output on failure, MUST NOT run format or fix commands, and SHALL print a non-blocking migration reminder when a model file is edited.

#### Scenario: Lint failure is fed back

- **WHEN** an edited `.py` file fails lint
- **THEN** the hook exits 2 and prints the tail of the lint output

#### Scenario: Non-Python file

- **WHEN** an edited file is not `.py`
- **THEN** the hook exits 0 without running anything

#### Scenario: No linter available

- **WHEN** `LITTLEDUCK_LINT_CMD` is unset and no supported linter is detected
- **THEN** the hook exits 0

#### Scenario: Model edited

- **WHEN** `models.py` is edited and lint passes
- **THEN** the hook prints a migration reminder and exits 0
