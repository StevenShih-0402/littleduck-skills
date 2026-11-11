## MODIFIED Requirements

### Requirement: Inputs are verified before any implementation

`frontend-processor` SHALL read the change's `proposal.md`, `design.md`, `openapi.yaml`, `tasks.md`, `handoff.md` and `specs/` from the worktree, and the frontend subdirectory from the repository `CLAUDE.md` `## agent-team 設定` (the repository root when single-side). It MUST stop and report without editing code when any is missing or `handoff.md` has no `## 狀態` block. When `.linear.md` exists its `branch` MUST match the current branch; otherwise the current branch MUST NOT be the default branch. Only `[FE]` tasks are handled.

#### Scenario: Missing tasks file

- **WHEN** the change directory has no `tasks.md`
- **THEN** the skill reports the missing file and makes no code change

#### Scenario: Backend not handed off in fullstack

- **WHEN** the structure is fullstack, `tasks.md` has unchecked `[BE]` tasks, and the stage is still `backend`
- **THEN** the skill stops and reports that the backend agent has not handed off, without editing code

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

The skill SHALL ship a PostToolUse hook script that lints only the single edited `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs` or `.vue` file, running in the nearest ancestor directory of that file (up to the git root) that has an eslint config, or in the git root when none has one. It SHALL use `LITTLEDUCK_FE_LINT_CMD` when set, otherwise eslint when that directory has an eslint config and a local eslint binary, and do nothing otherwise. It MUST exit 2 with the tail of the lint output on failure and MUST NOT run fix or type-check commands.

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
