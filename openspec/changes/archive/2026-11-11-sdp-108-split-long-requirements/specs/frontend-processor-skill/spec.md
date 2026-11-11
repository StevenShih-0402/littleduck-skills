## MODIFIED Requirements

### Requirement: Inputs are verified before any implementation

`frontend-processor` SHALL read the change's `proposal.md`, `design.md`, `openapi.yaml`, `tasks.md`, `handoff.md` and `specs/` from the worktree, and the frontend subdirectory from the repository `CLAUDE.md` `## agent-team 設定` (the repository root when single-side). It MUST stop and report without editing code when any is missing or `handoff.md` has no `## 狀態` block. Only `[FE]` tasks are handled.

#### Scenario: Missing tasks file

- **WHEN** the change directory has no `tasks.md`
- **THEN** the skill reports the missing file and makes no code change

#### Scenario: Backend not handed off in fullstack

- **WHEN** the structure is fullstack, `tasks.md` has unchecked `[BE]` tasks, and the stage is still `backend`
- **THEN** the skill stops and reports that the backend agent has not handed off, without editing code

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

## ADDED Requirements

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
