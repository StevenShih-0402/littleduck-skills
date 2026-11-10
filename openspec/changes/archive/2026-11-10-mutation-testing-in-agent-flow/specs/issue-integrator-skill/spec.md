# Spec Delta

## ADDED Requirements

### Requirement: Mutation testing verifies tests on designated critical modules

In a check run the skill SHALL run mutation testing on the modules or paths listed under each side's `design.md` `## 變異測試目標`, using the mutation command and pass threshold from that repo's `CLAUDE.md`, and MUST NOT trust a previous agent's mutation report.

#### Scenario: Surviving mutants below threshold

- **WHEN** a designated module's mutation score is below the repo's threshold
- **THEN** the check fails and that side is returned to its developer with the mutation command as the reproduction step, counted under the same per-target return limit

#### Scenario: Mutation command not configured

- **WHEN** the repo's `CLAUDE.md` documents no mutation-testing command
- **THEN** the skill records mutation testing as skipped in `handoff.md` and the report, and does not fail the check for that reason

#### Scenario: No critical modules designated

- **WHEN** a side's `design.md` `## 變異測試目標` reads 「無」
- **THEN** the skill records mutation testing as not applicable and runs none

#### Scenario: Previous agent claimed the tests are strong

- **WHEN** `handoff.md` states the tests already pass mutation testing
- **THEN** the skill still runs mutation testing itself and reports its own result

### Requirement: Mutation results are recorded in the hand-off

In a check run the skill SHALL record each designated module's mutation outcome — surviving mutants or score, whether it met the threshold, or that it was skipped or not applicable — in that side's `handoff.md` integrator section and in the check report.

#### Scenario: Result written back

- **WHEN** mutation testing runs against a designated module
- **THEN** that module's score and threshold verdict appear in the side's `handoff.md` integrator section and the check report
