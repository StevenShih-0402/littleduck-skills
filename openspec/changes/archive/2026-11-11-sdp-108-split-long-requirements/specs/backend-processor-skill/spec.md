## MODIFIED Requirements

### Requirement: Post-edit lint hook

The skill SHALL ship a PostToolUse hook script that lints only the single edited `.py` file, using `LITTLEDUCK_LINT_CMD` when set, otherwise an auto-detected linter, and does nothing when none is found. It MUST exit 2 with the lint output on failure and MUST NOT run format or fix commands.

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

#### Scenario: Lint config in the backend subdirectory

- **WHEN** `backend/pyproject.toml` has `[tool.ruff]`, and `backend/app/views.py` is edited
- **THEN** the lint command runs in `backend/` with the path `app/views.py`

## ADDED Requirements

### Requirement: Backend lint hook runs in the nearest lint root

The backend post-edit lint hook SHALL run the lint command in the nearest ancestor directory of the edited file, up to the git root, that has an executable `pants` or a `pyproject.toml` with `[tool.ruff]`, passing the file path relative to that directory, and SHALL use the git root when no ancestor qualifies.

#### Scenario: Ruff config only at the git root

- **WHEN** `backend/pyproject.toml` has no `[tool.ruff]`, the root `pyproject.toml` has it, and `backend/app/views.py` is edited
- **THEN** the lint command runs in the git root with the path `backend/app/views.py`

### Requirement: Backend lint hook reminds about migrations

When the edited file is a model file (`models.py` or a file under a `models/` directory), the backend post-edit lint hook SHALL print a reminder to check for a needed migration, without changing its exit status.

#### Scenario: Model file under a models directory

- **WHEN** `app/models/order.py` is edited and lint passes
- **THEN** the hook prints a migration reminder and exits 0
