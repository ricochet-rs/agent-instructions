---
name: development-flow
description: Follow the shared ricochet-rs development lifecycle when implementing, fixing, refactoring, testing, or reviewing code in an organization repository.
---

# Development flow

Read the repository instructions before acting.
Treat repository and component instructions as authoritative when they narrow or override this workflow.

## Work

1. State a plan for the immediate next step before writing code.
2. Read only the files directly needed for that step.
3. Extend the existing domain model and implementation instead of adding a parallel abstraction.
4. Complete one coherent change at a time.
5. Validate the change before moving to another task.
6. Apply user corrections and continue the active task.

Do not manage Git unless the user explicitly requests it.
Do not leave the repository in a known non-compiling or otherwise invalid state.

## Validate

Use repository-provided commands such as `just`, formatters, linters, and test targets.
Run the narrowest useful check during iteration and the repository-required full check before completion.
Report commands that were not run and why.

## Communicate

Lead with the result.
Describe material behavior changes and validation evidence.
Do not claim success from inspection alone when an executable check is available.
