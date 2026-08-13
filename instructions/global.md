# Ricochet development instructions

## Scope

Apply these instructions to work in repositories owned by `ricochet-rs`.
Repository and component instructions may narrow or override them.

## Attribution

Do not add AI attribution trailers or generated-by footers to commits, pull requests, or documentation.

## Planning and execution

Provide a plan before writing code.
Scope the plan to the immediate next step.
Work on one task at a time and validate it before moving on.
Read only files directly needed for the current step.
Treat an interruption as a correction and continue the active task.
Never manage Git unless the user explicitly requests it.

## Design

Extend the existing implementation instead of adding a parallel structure that performs the same job.
Connect new types to the existing domain model.
Prefer a smaller, cohesive implementation over speculative abstractions.
Name functions for what they do.

## Commits and pull requests

Use Conventional Commit titles in the imperative present tense.
Use `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`, `perf`, or `ci` unless a repository defines additional types.
Do not bypass commit hooks.
Use GitHub tooling for repositories hosted in the `ricochet-rs` organization.

## Prose

Write one sentence per line in Markdown and other prose files.
Do not hard-wrap sentences.
Do not use em dashes in user-facing text.
Put code-block comments on their own line above the command.

## Validation

Use repository-provided `just` commands when available.
Run formatters, linters, compilation checks, and relevant tests before declaring completion.
Do not leave a repository in a known invalid state.

## Safety

Preserve unrelated user changes.
Do not read secret directories or credential files.
Do not use destructive Git commands unless the user explicitly requests the exact operation.
