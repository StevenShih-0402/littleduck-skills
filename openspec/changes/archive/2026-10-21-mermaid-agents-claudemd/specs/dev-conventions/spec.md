# Spec Delta

## Purpose

以一份通用的 `CLAUDE.md` 集中記錄跨專案共通的開發習慣，讓新專案安裝後 Claude Code 即遵循相同的開發原則。

## ADDED Requirements

### Requirement: Shared conventions document

The repository SHALL contain a root `CLAUDE.md` that consolidates project-agnostic development conventions gathered from the source projects, covering at least: test-first development with AAA-structured tests, SOLID principles, appropriate use of design patterns, Traditional Chinese comments and commit messages, a two-line file header comment, mermaid diagrams in design documents, linting only the changed files, and the ban on structural-existence assertions in tests.

#### Scenario: Conventions present

- **WHEN** the repository's root `CLAUDE.md` is read
- **THEN** each of the listed conventions is stated as a rule

### Requirement: Conventions exclude project-bound rules

The conventions document MUST NOT include rules bound to a specific project's stack, infrastructure, or business domain (e.g. Pants, docker compose layouts, deployment hosts, RBAC lifecycle hooks).

#### Scenario: No project-bound content

- **WHEN** the document is searched for `ignsw`, `Pants`, `libs/common`, or `gunicorn`
- **THEN** no matches are found
