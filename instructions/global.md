# Ricochet development instructions

## Scope

Apply these instructions to work in repositories owned by `ricochet-rs`.
Repository and component instructions may narrow or override them.

## Attribution

Do not add AI attribution trailers or generated-by footers to commits, pull requests, or documentation.

## Planning and execution

State a plan for the immediate next step before writing code.
Read only files directly needed for that step.
Complete one coherent change and validate it before starting another.
Change only the files, sections, and lines the request names.
When a request names a subset, treat the rest as out of scope even when it becomes inconsistent.
Report adjacent changes as a question at the end of the reply instead of making them.
Err toward asking for clarification rather than assuming.
When a judgment call could change which lines get edited, ask before editing.
Treat an interruption as a correction, apply it, and continue the active task.
Never manage Git unless the user explicitly requests it.
Do not say "You're right" or "You're absolutely right".

After human review, read and follow `skills/digesting-review-feedback/SKILL.md` from this checkout.
Before writing a pull-request description, read and follow `skills/session-retro/SKILL.md` from this checkout, including its body format and its `Instructions-PR:` trailer.

## Design

Extend the existing implementation instead of adding a parallel structure that performs the same job.
Connect new types to the existing domain model.
Prefer a smaller, cohesive implementation over speculative abstractions.
Name functions for what they do.
Refactor when the requested change exposes a clear quality improvement within scope.
When a change makes an instruction file inaccurate, correct it in the same pull request.

## Commits and pull requests

Use Conventional Commit titles in the imperative present tense.
Use `feat`, `fix`, `refactor`, `chore`, `docs`, `style`, `test`, `perf`, or `ci` unless a repository defines additional types.
Name a branch with a type prefix such as `fix/`, `docs/`, `feat/`, `enh/`, or `refactor/`, followed by a short description of the change.
Never prefix a branch with a user, agent, or tool name, and never copy the prefix of an existing branch.
Do not bypass commit hooks.
Do not create draft pull requests.
Use GitHub tooling for repositories hosted in the `ricochet-rs` organization.

## Prose

Write one sentence per line in Markdown and other prose files.
Do not hard-wrap sentences.
Do not use em dashes in user-facing text.
Write two sentences, or use a comma, colon, or parentheses.
Put code-block comments on their own line above the command.

For user-facing release notes, use section and area headings to classify changes.
Write each item as one bullet containing one complete sentence that leads with the user-visible behavior or outcome in present tense.
Do not prefix an item with a bold title or a colon-separated label that restates the sentence.
Use bold only for a literal UI label, command, or named feature that readers must recognize, and incorporate it naturally into the sentence.
Omit maintenance, CI, dependency update, and internal refactor entries unless they change user-visible behavior.

Names should carry the explanation in code.
Use comments for information a name cannot express.
Use module-level documentation when it explains the purpose of a module.
Keep method documentation to one concise line whenever possible.
Do not use comments to narrate history, justify what code does not do, or recount the bug that motivated a change.
Comment surprising script and Containerfile behavior rather than routine commands or package lists.
Do not generalize a review request beyond the code or comment it addresses.

## Validation

Use repository-provided commands such as `just`, formatters, linters, and test targets.
Run the narrowest useful check during iteration and the repository-required full check before completion.
Report commands that were not run and why.
Do not leave a repository in a known invalid state.

## Reporting

Lead with the result.
Describe material behavior changes and validation evidence.
Do not claim success from inspection alone when an executable check is available.

## Safety

Preserve unrelated user changes.
Do not read secret directories or credential files.
Do not use destructive Git commands unless the user explicitly requests the exact operation.
