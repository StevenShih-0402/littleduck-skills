# Spec Delta

## ADDED Requirements

### Requirement: Design designates mutation-test targets

Each side's `design.md` SHALL contain a `## 變異測試目標` section naming the change's critical modules or paths whose test effectiveness must be verified, scoped to the change rather than the whole project, and SHALL tag each `tasks.md` task that implements such a module.

#### Scenario: Change touches critical logic

- **WHEN** the change adds or alters a permission check or a state machine
- **THEN** that side's `design.md` lists the module or path under `## 變異測試目標`
- **AND** the implementing `tasks.md` task names it as a mutation-test target

#### Scenario: Change has no critical logic

- **WHEN** the change touches no permission, state-machine, or similarly critical logic
- **THEN** the `## 變異測試目標` section reads 「無」 and states why

#### Scenario: Architect does not pick the tool

- **WHEN** the architect writes the `## 變異測試目標` section
- **THEN** it names only modules or paths, not a mutation-testing tool, command, or pass threshold
