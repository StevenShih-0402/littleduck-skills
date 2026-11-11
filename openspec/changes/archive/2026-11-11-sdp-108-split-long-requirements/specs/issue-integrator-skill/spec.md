## MODIFIED Requirements

### Requirement: Checks are executed, not trusted

In a check run the skill SHALL stop unless the stage is `integrating`, then itself run, for each affected side inside its declared subdirectory, the tests, lint, type-check and migrations forward and backward when present (commands from the repository `CLAUDE.md` or `design.md`), and `openspec validate`. It MUST NOT accept a previous agent's report instead.

#### Scenario: Previous agent claimed tests pass

- **WHEN** `handoff.md` says all tests passed
- **THEN** the skill still runs the tests and reports its own result

#### Scenario: Fullstack checks per subdirectory

- **WHEN** a fullstack change affects both sides with backend subdirectory `backend/` and frontend subdirectory `frontend/`
- **THEN** the backend commands run in `backend/`, the frontend commands run in `frontend/`, and a failure is returned to the agent of the side whose command failed

#### Scenario: Run verification configured

- **WHEN** the repository `CLAUDE.md` gives a start command and observation points
- **THEN** the skill starts the product, checks each observation point, stops what it started, and fails the check when an observation point does not hold

#### Scenario: Run verification not configured

- **WHEN** the repository `CLAUDE.md` gives no start command for run verification
- **THEN** the skill records run verification as skipped in `handoff.md` and the report, and does not fail the check for that reason

#### Scenario: Change-specific observation points in design.md

- **WHEN** run verification is configured and `design.md` lists observation points for this change
- **THEN** the skill checks those points in the same run as the repository's own points, and lists each one's result separately in `handoff.md` and the report

#### Scenario: Screenshot observation point matches

- **WHEN** an observation point gives a screenshot command and an expected screen, and the screenshot taken while the product runs clearly shows the expected screen
- **THEN** the point passes, and the screenshot is saved outside the worktree so it is never committed

#### Scenario: Screenshot clearly does not match

- **WHEN** the screenshot shows a blank page, an error page, or lacks an element the expected screen names
- **THEN** the check fails and returns to the developer agent of the side that owns the screen, with the screenshot command as the reproduction step

#### Scenario: Screenshot result uncertain

- **WHEN** the skill cannot tell from the screenshot whether the expected screen is shown
- **THEN** the point does not fail the check, and the skill records it as a risk in `handoff.md` with the screenshot path so the pre-PR review can see it

#### Scenario: Screenshot tool unavailable

- **WHEN** the screenshot command is not installed or its browser cannot start in this environment
- **THEN** the skill records that point as skipped with the error message, and does not fail the check for that reason

### Requirement: Passing changes are recut, pushed with lease, and opened as PRs

In a finish run, dispatched only after the pre-PR review has passed, the skill SHALL record the current HEAD, soft-reset to the merge-base with the base branch passed in (or, when the PR already exists, to the HEAD recorded at the previous finish, so earlier commits keep their SHAs), recommit by feature following `issue-solver`, and verify `git diff <old> HEAD` is empty, restoring the old HEAD otherwise.

#### Scenario: Lease rejected

- **WHEN** the remote branch moved since the recorded HEAD
- **THEN** the push is rejected and the skill stops without retrying with `--force`

#### Scenario: Recut changes content

- **WHEN** the recut tree differs from the old HEAD
- **THEN** the skill resets back to the old HEAD and stops

#### Scenario: Review notes carried into the PR

- **WHEN** `review.md` lists findings marked as PR notes
- **THEN** the opened or reused PR body includes those findings

#### Scenario: Finish after a PR-stage return

- **WHEN** a finish run happens while the PR already exists and `handoff.md` records the previous finish HEAD
- **THEN** only the commits after that HEAD are recut, so the previous finish HEAD stays an ancestor and later review rounds can use it as the start of their range

#### Scenario: Stage after opening the PR

- **WHEN** the finish run opens or reuses the PR
- **THEN** the stage is `pr-checking` and exactly one PR exists for the branch

## ADDED Requirements

### Requirement: Check run includes run verification

In a check run the skill SHALL also run the run verification described in the repository `CLAUDE.md` when it gives a start command, together with the change's `design.md` observation points.

#### Scenario: Observation point fails

- **WHEN** a command observation point does not produce its expected output
- **THEN** the check fails and returns to the developer agent of the side the point belongs to

### Requirement: Required services are started by the user

When a service required by the checks (for example a database or cache) is not running, the skill SHALL stop and ask the user to start it, and MUST NOT start it itself.

#### Scenario: Database not running

- **WHEN** the tests need a database that is not running
- **THEN** the skill stops and asks the user to start it, without starting it

### Requirement: Finish run pushes with lease and opens one PR

After a successful recut, the finish run SHALL push with `--force-with-lease=<branch>:<old>`, open or reuse one PR against the base branch, append the `review.md` PR-note findings to the PR body, and set the stage to `pr-checking`. It MUST NOT use plain `--force`.

#### Scenario: Push after recut

- **WHEN** the recut tree equals the old HEAD
- **THEN** the branch is pushed with `--force-with-lease=<branch>:<old>`, never with plain `--force`
