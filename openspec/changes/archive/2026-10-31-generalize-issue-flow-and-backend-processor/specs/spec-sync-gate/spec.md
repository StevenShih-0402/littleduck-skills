# Spec Delta

## Purpose

讓專案以一份設定檔宣告「程式路徑 → 規格」的對應，偵測改了程式卻漏寫規格的情形；OpenSpec 格式的規格只檢查 change 是否帶有 delta、實際寫入交給歸檔時的 sync，自由格式文件則檢查文件本身。

## ADDED Requirements

### Requirement: Rules are declared in a project config file

A project SHALL declare spec sync rules in `openspec/spec-sync.yaml`. Each rule MUST have a name, one or more path globs that may capture named segments (`{name}`), optional exclude globs, a description of when an exemption is allowed, and exactly one target: a `capability` path (an OpenSpec capability under `openspec/specs/`) or a `spec_dir` folder plus the `spec_files` that count as an update. Both targets may use the captured segments.

#### Scenario: Captured segment maps to a folder

- **WHEN** a rule has path `projects/{proj}/compose/**` and spec folder `projects/{proj}/docs/specs/compose_{proj}/`, and `projects/shop/compose/web/Dockerfile` changed
- **THEN** the affected spec folder is `projects/shop/docs/specs/compose_shop/`

#### Scenario: Captured segment maps to a capability

- **WHEN** a rule has path `src/apps/{app}/**` and capability `apps/{app}`, and `src/apps/billing/views.py` changed
- **THEN** the affected capability is `apps/billing`

#### Scenario: Excluded path

- **WHEN** the only changed path under a rule matches one of its exclude globs
- **THEN** that rule is not affected

#### Scenario: Rule with two targets

- **WHEN** a rule declares both `capability` and `spec_dir`
- **THEN** the gate reports the rule as invalid and treats it as failing until the config is fixed

### Requirement: Gate is skipped without a config file

When `openspec/spec-sync.yaml` does not exist, the gate SHALL be skipped entirely and the skill MUST continue as it would without the gate.

#### Scenario: Project without config

- **WHEN** `issue-solver` runs in a project that has no `openspec/spec-sync.yaml`
- **THEN** no spec sync question is asked and the report states the gate as not applicable

### Requirement: Changed paths come from the whole branch

The gate SHALL evaluate every path changed since the merge base with the default remote branch plus untracked files, including deletions and renames.

#### Scenario: Uncommitted work is included

- **WHEN** a matching source file is untracked and not yet committed
- **THEN** the gate still treats its rule as affected

### Requirement: A capability target passes when the change carries its delta

An affected capability SHALL pass only if the active change contains a delta spec for it at `openspec/changes/<change>/specs/<capability>/spec.md`. The gate MUST NOT require the main spec under `openspec/specs/` to be edited, because archiving syncs the delta into it.

#### Scenario: Delta present

- **WHEN** `apps/billing` is affected and the change has `specs/apps/billing/spec.md`
- **THEN** the capability passes and the report notes it will be written to the main spec on archive

#### Scenario: Delta missing

- **WHEN** `apps/billing` is affected and the change has no delta for it
- **THEN** the capability fails even if `openspec/specs/apps/billing/spec.md` was edited directly

### Requirement: A spec folder target passes only when its files changed

An affected spec folder SHALL pass only if at least one of the rule's `spec_files` inside it is among the changed paths. A folder that does not exist MUST fail. Delta specs under `openspec/changes/` MUST NOT count for a spec folder target.

#### Scenario: Folder missing

- **WHEN** a rule maps a changed path to a spec folder that does not exist
- **THEN** that folder fails the gate

#### Scenario: Spec updated

- **WHEN** the affected folder's `spec.md` is among the changed paths
- **THEN** that folder passes

### Requirement: Gate runs during implementation and again before archiving

The gate SHALL be checked when implementation finishes, so missing deltas or documents are written while the change is still active, and again as the final gate before archiving. Only the final gate offers an exemption.

#### Scenario: Missing delta found during implementation

- **WHEN** `issue-processor` finishes `/opsx:apply` and a capability target fails
- **THEN** the user is asked whether to add the delta now or leave the decision to `issue-solver`

### Requirement: User decides how to resolve a failed final gate

When any target fails at the final gate, the gate SHALL list the failing targets with their triggering paths and ask the user to choose: fix the specs first (the run stops), declare an exemption with a reason per target (allowed only under the rule's exemption description), or abort.

#### Scenario: User declares exemption

- **WHEN** the user chooses to declare an exemption and gives a reason for each failing target
- **THEN** the run continues and the reasons are recorded for the PR body

#### Scenario: User aborts

- **WHEN** the user chooses abort
- **THEN** nothing is archived, committed or pushed

### Requirement: Format is documented with an example

The repository SHALL ship a document describing the config format and an example config covering a capability rule, a single-capture spec folder rule, and paths that map to more than one target; installing `issue-solver` or `backend-processor` SHALL install them.

#### Scenario: Installing issue-solver brings the format doc

- **WHEN** `install.sh issue-solver <target>` is run
- **THEN** the target receives the format document and the example config
