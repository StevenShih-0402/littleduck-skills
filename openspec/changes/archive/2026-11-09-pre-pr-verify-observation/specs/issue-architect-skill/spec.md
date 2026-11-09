# Spec Delta

## ADDED Requirements

### Requirement: Design lists change-specific run verification points

Each side's `design.md` SHALL contain a `## 執行驗證觀察點` section listing observation points that show this change works while the product runs, written in the same format as the repo's `CLAUDE.md` run verification section: a command with its expected output, or a screenshot command with the expected screen. Points SHALL cover only this change's behavior, not repeat the repo's own points.

#### Scenario: Change with observable behavior

- **WHEN** the change adds or alters behavior visible through a command, an HTTP response, or a page
- **THEN** that side's `design.md` lists at least one observation point for it under `## 執行驗證觀察點`

#### Scenario: Nothing observable at run time

- **WHEN** the change has no behavior that can be observed by running the product (for example, documentation only)
- **THEN** the section says 「無」 and gives the reason

#### Scenario: Repo has no run verification setup

- **WHEN** the repo's `CLAUDE.md` has no run verification section
- **THEN** the skill still writes the section, notes that the points will be skipped until the repo adds a start command, and lists this as an open question in its report
