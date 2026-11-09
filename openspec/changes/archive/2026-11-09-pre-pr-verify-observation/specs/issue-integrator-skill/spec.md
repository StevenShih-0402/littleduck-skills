# Spec Delta

## MODIFIED Requirements

### Requirement: Checks are executed, not trusted

In a check run the skill SHALL stop unless every affected side's stage is `integrating`, then itself run each side's tests, lint, type-check, migrations forward and backward when present (commands from that repo's `CLAUDE.md` or `design.md`), the run verification described in that repo's `CLAUDE.md` when present, and `openspec validate`. It MUST NOT accept a previous agent's report instead, and SHALL ask the user to start any required service that is down.

#### Scenario: Previous agent claimed tests pass

- **WHEN** `handoff.md` says all tests passed
- **THEN** the skill still runs the tests and reports its own result

#### Scenario: Run verification configured

- **WHEN** the repo's `CLAUDE.md` gives a start command and observation points
- **THEN** the skill starts the product, checks each observation point, stops what it started, and fails the check when an observation point does not hold

#### Scenario: Run verification not configured

- **WHEN** the repo's `CLAUDE.md` gives no start command for run verification
- **THEN** the skill records run verification as skipped in `handoff.md` and the report, and does not fail the check for that reason

#### Scenario: Change-specific observation points in design.md

- **WHEN** run verification is configured and the side's `design.md` lists observation points for this change
- **THEN** the skill checks those points in the same run as the repo's own points, and lists each one's result separately in `handoff.md` and the report

#### Scenario: Screenshot observation point matches

- **WHEN** an observation point gives a screenshot command and an expected screen, and the screenshot taken while the product runs clearly shows the expected screen
- **THEN** the point passes, and the screenshot is saved outside the worktree so it is never committed

#### Scenario: Screenshot clearly does not match

- **WHEN** the screenshot shows a blank page, an error page, or lacks an element the expected screen names
- **THEN** the check fails and returns to that side's developer agent, with the screenshot command as the reproduction step

#### Scenario: Screenshot result uncertain

- **WHEN** the skill cannot tell from the screenshot whether the expected screen is shown
- **THEN** the point does not fail the check, and the skill records it as a risk in `handoff.md` with the screenshot path so the pre-PR review can see it

#### Scenario: Screenshot tool unavailable

- **WHEN** the screenshot command is not installed or its browser cannot start in this environment
- **THEN** the skill records that point as skipped with the error message, and does not fail the check for that reason
