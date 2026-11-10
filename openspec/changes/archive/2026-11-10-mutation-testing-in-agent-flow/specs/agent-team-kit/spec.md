# Spec Delta

## ADDED Requirements

### Requirement: Team-hq docs place the mutation-testing check

The kit's team-hq `CLAUDE.md` 層層把關 section and the setup document SHALL document mutation testing as a check that runs in the integrator check phase only, against the critical modules the architect designates in `design.md`, using the mutation command and threshold from each repo's own `CLAUDE.md`, skipped and non-blocking when a repo documents no such command. They SHALL state that the developer and reviewer agents do not run it.

#### Scenario: Check flow documented

- **WHEN** the team-hq `CLAUDE.md` 層層把關 section is read
- **THEN** it lists mutation testing under the integrator check phase, scoped to the architect's designated critical modules, with the command and threshold coming from each repo's `CLAUDE.md`

#### Scenario: Setup document names the per-repo config

- **WHEN** the setup document is read
- **THEN** it states that a repo enables mutation testing by documenting its mutation command and threshold in that repo's `CLAUDE.md`, and that without it the check is skipped and non-blocking
