# frontend-processor-skill Specification

## Purpose
提供多 Agent 流程中前端實作棒的通用 skill：依 OpenSpec 交接資料與 openapi.yaml 在 worktree 的前端子目錄逐項實作、可中斷接續，並附帶編輯後自動 lint 的 hook。

## Requirements

### Requirement: Inputs are verified before any implementation

`frontend-processor` SHALL read the change's `proposal.md`, `design.md`, `openapi.yaml`, `tasks.md`, `handoff.md` and `specs/` from the worktree, and the frontend subdirectory from the repository `CLAUDE.md` `## agent-team 設定` (the repository root when single-side). It MUST stop and report without editing code when any is missing or `handoff.md` has no `## 狀態` block. Only `[FE]` tasks are handled.

#### Scenario: Missing tasks file

- **WHEN** the change directory has no `tasks.md`
- **THEN** the skill reports the missing file and makes no code change

#### Scenario: Backend not handed off in fullstack

- **WHEN** the structure is fullstack, `tasks.md` has unchecked `[BE]` tasks, and the stage is still `backend`
- **THEN** the skill stops and reports that the backend agent has not handed off, without editing code

### Requirement: Work resumes safely after interruption

On start the skill SHALL stop when the worktree has uncommitted changes or the branch is behind or diverged from its remote, push first when only ahead, and re-run the verification of the last checked `[FE]` task, unchecking it on failure. It MUST NOT stash, reset, discard or commit leftover changes on its own.

#### Scenario: Leftover edits

- **WHEN** the worktree has an uncommitted `.tsx` file
- **THEN** the skill stops and lists the file without touching it

### Requirement: Types and mocks come from the contract

The skill SHALL treat `openapi.yaml` as the only integration contract and MUST NOT edit it. When the backend has not finalised it, the skill SHALL generate types and mocks from it using the project's own generator and mock mechanism, and MUST NOT run a generator that overwrites a whole existing output directory with the partial change contract. When the backend finalises a different contract, the skill SHALL resync types and mocks.

#### Scenario: Partial contract

- **WHEN** the project generates its API client into one directory from the full remote schema
- **THEN** the skill generates from the change's `openapi.yaml` into a temporary directory and copies only this change's models and services

#### Scenario: Contract problem

- **WHEN** the contract cannot serve the screen as specified
- **THEN** the skill records the problem in `handoff.md` and reports it should be returned to the backend agent or architect, leaving `openapi.yaml` unchanged

### Requirement: Each task is committed and pushed on its own

For each `[FE]` task the skill SHALL verify, check it with a one-line note, update the status block, stage only the listed paths, commit as `wip(<ISSUE-ID>): <task number> <summary>`, and push. It MUST NOT use `git add -A`/`git add .`, `--no-verify`, or force push.

#### Scenario: Task completed

- **WHEN** task 3.1 passes its verification
- **THEN** a commit `wip(ENG-200): 3.1 …` with the task's files, `tasks.md` and `handoff.md` is pushed and the worktree is clean

### Requirement: Stack-specific commands come from the project

Lint, type-check and test commands SHALL be taken from the repository `CLAUDE.md` or the change's `design.md` and run inside the frontend subdirectory; when neither states one the skill MUST stop and report rather than guess.

#### Scenario: No documented test command

- **WHEN** neither document names a test command
- **THEN** the skill stops with the missing command in its report

### Requirement: Specs are synced within the task

When the repository has `openspec/spec-sync.yaml`, a task that changes code matched by a rule SHALL in the same task write the change's delta for a `capability` target or update the document for a `spec_dir` target, or write an exemption line in `handoff.md`'s frontend section when the rule's exemption description applies.

#### Scenario: Capability code changed

- **WHEN** a task edits a path mapped to a capability
- **THEN** the same task's commit includes that capability's delta under the change directory

### Requirement: Hand-off leaves a clean, synced state

The skill SHALL finish by appending a frontend section to `handoff.md` (including what still relies on mocks), setting the status block's stage to `integrating`, and pushing so the worktree is clean and not ahead. It MUST NOT open a PR, archive, edit `proposal.md`, or edit files outside the frontend subdirectory and the change directory.

#### Scenario: Normal completion

- **WHEN** all `[FE]` tasks are done and lint, type-check and tests pass
- **THEN** the stage is `integrating` and `git status -sb` shows no ahead commits

### Requirement: Post-edit lint hook

The skill SHALL ship a PostToolUse hook script that lints only the single edited `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs` or `.vue` file, using `LITTLEDUCK_FE_LINT_CMD` when set, otherwise eslint when the lint directory has an eslint config and a local eslint binary, and doing nothing otherwise. It MUST exit 2 with the tail of the lint output on failure and MUST NOT run fix or type-check commands.

#### Scenario: Lint failure is fed back

- **WHEN** `LITTLEDUCK_FE_LINT_CMD=false` and a `.tsx` file is edited
- **THEN** the hook exits 2

#### Scenario: Unsupported file

- **WHEN** an edited file is `.py`
- **THEN** the hook exits 0 without running anything

#### Scenario: No linter available

- **WHEN** the variable is unset and neither the file's ancestors nor the git root have an eslint config
- **THEN** the hook exits 0

#### Scenario: Eslint config in the frontend subdirectory

- **WHEN** `frontend/eslint.config.js` exists, the git root has no eslint config, and `frontend/src/App.tsx` is edited
- **THEN** the lint command runs in `frontend/` with the path `src/App.tsx`

### Requirement: Frontend work runs on the issue branch

Before editing code, `frontend-processor` SHALL check that the current branch equals the `branch` in `.linear.md` when that file exists, and otherwise that the current branch is not the default branch, and MUST stop and report when the check fails.

#### Scenario: Branch differs from the handoff file

- **WHEN** `.linear.md` names `feature/ENG-1-x` but the worktree is on another branch
- **THEN** the skill stops and reports the mismatch without editing code

### Requirement: Frontend lint hook runs in the nearest eslint directory

The frontend post-edit lint hook SHALL run the lint command in the nearest ancestor directory of the edited file, up to the git root, that has an eslint config, passing the file path relative to that directory, and SHALL use the git root when no ancestor has one.

#### Scenario: Eslint config only at the git root

- **WHEN** only the git root has `.eslintrc.json` and `frontend/src/App.tsx` is edited with `LITTLEDUCK_FE_LINT_CMD` set
- **THEN** the lint command runs in the git root with the path `frontend/src/App.tsx`
