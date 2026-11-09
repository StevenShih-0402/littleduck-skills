# Spec Delta

## MODIFIED Requirements

### Requirement: Gate runs during implementation and again before archiving

The gate SHALL be checked when implementation finishes and again as the final gate before archiving; only the final gate offers an exemption. In the multi-agent workflow the developer skills check within each task and `issue-integrator` is the final gate: a failing target passes only with an exemption line in `handoff.md`, which the orchestrator asks the user to confirm right after the integrator check; otherwise it is returned to the developer agent.

#### Scenario: Missing delta found during implementation

- **WHEN** `issue-processor` finishes `/opsx:apply` and a capability target fails
- **THEN** the user is asked whether to add the delta now or leave the decision to `issue-solver`

#### Scenario: Integrator finds a target without exemption

- **WHEN** `issue-integrator` checks a change whose backend diff triggers a rule, the target was not updated, and `handoff.md` has no exemption line for it
- **THEN** the check fails and the change is returned to the backend agent

#### Scenario: Integrator finds an exempted target

- **WHEN** the target was not updated but `handoff.md` has `- **規格免同步**：<target> — <reason>`
- **THEN** the check passes, the exemption is listed in the report, and the orchestrator asks the user to confirm it before the pre-PR review starts
