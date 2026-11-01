## MODIFIED Requirements

### Requirement: Gate runs during implementation and again before archiving

The gate SHALL be checked when implementation finishes, so missing deltas or documents are written while the change is still active, and again as the final gate before archiving. Only the final gate offers an exemption. In the multi-agent workflow `backend-processor` and `frontend-processor` check within each task, and `issue-integrator` is the final gate: a failing target passes only when the developer's `handoff.md` holds an exemption line for it, and such exemptions SHALL be listed for the user to confirm at the pre-archive checkpoint; a failing target without one SHALL be returned to the responsible developer agent.

#### Scenario: Missing delta found during implementation

- **WHEN** `issue-processor` finishes `/opsx:apply` and a capability target fails
- **THEN** the user is asked whether to add the delta now or leave the decision to `issue-solver`

#### Scenario: Integrator finds a target without exemption

- **WHEN** `issue-integrator` checks a change whose backend diff triggers a rule, the target was not updated, and `handoff.md` has no exemption line for it
- **THEN** the check fails and the change is returned to the backend agent

#### Scenario: Integrator finds an exempted target

- **WHEN** the target was not updated but `handoff.md` has `- **規格免同步**：<target> — <reason>`
- **THEN** the check passes and the exemption is listed in the report for checkpoint 2
