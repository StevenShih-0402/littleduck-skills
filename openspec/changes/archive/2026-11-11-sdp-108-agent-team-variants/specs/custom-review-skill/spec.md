## MODIFIED Requirements

### Requirement: Reviewer works from prepared inputs and stops when any is missing

`custom-review` SHALL run in one of two modes named by the dispatching prompt. In review mode it SHALL take the change directory (`proposal.md`, `tasks.md`, `specs/`, `openapi.yaml`), one prepared diff file, and the repository `CLAUDE.md`. In rating mode it SHALL take the same inputs plus the `/code-review` and `/security-review` findings. It MUST stop and report when any input is missing, because the reviewer is read-only.

#### Scenario: Missing diff file

- **WHEN** the prompt names a change directory but no prepared diff file
- **THEN** the skill stops and reports the missing input without producing a verdict

#### Scenario: No code-review findings supplied

- **WHEN** the prompt names review mode and supplies no `/code-review` findings
- **THEN** the skill still reviews requirement, test, contract, edge-case and logic coverage

#### Scenario: Unknown mode

- **WHEN** the prompt names neither review mode nor rating mode
- **THEN** the skill stops and reports rather than guessing

### Requirement: Review checks requirement and test coverage against the change

The review SHALL verify that every acceptance criterion in `proposal.md`, every `### Requirement` / `#### Scenario` in the change's delta specs, and every `tasks.md` item is both implemented in the diff and covered by a test; and that the implementation matches `openapi.yaml` (paths, methods, fields, types, status codes) on both the backend and the frontend side where the change has an API. Each finding SHALL name the side (`[BE]` or `[FE]`) it belongs to.

#### Scenario: Scenario without a test

- **WHEN** a delta spec scenario is implemented but no test exercises it
- **THEN** the review records a finding naming that scenario and its side

#### Scenario: Contract drift

- **WHEN** an implemented response field is absent from `openapi.yaml`
- **THEN** the review records a contract finding with the file and line

#### Scenario: Frontend uses a field the contract lacks

- **WHEN** a fullstack diff has frontend code reading a response field that `openapi.yaml` does not define
- **THEN** the review records a `[FE]` contract finding with the file and line
