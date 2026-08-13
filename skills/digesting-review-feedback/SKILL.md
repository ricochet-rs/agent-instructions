---
name: digesting-review-feedback
description: Apply human pull-request review feedback and preserve durable organization lessons through a paired pull request in ricochet-rs/agent-instructions. Use after changes are requested, a batch of inline comments arrives, or a reviewer identifies an over-engineered or incorrect approach.
---

# Digest review feedback

Read the complete review context before changing code.
Separate requested implementation changes from durable guidance.

## Apply the review

1. Group comments that share one underlying cause.
2. Verify each comment against the current code rather than applying it mechanically.
3. Implement the smallest coherent correction.
4. Run the repository validation required for the affected code.
5. Re-read the review to ensure every actionable point is addressed.

## Preserve durable guidance

Identify lessons that would prevent a future session from repeating the same mistake.
Write only rules that generalize beyond the reviewed diff.
Put organization-wide rules and reusable workflow changes in `ricochet-rs/agent-instructions`.
Keep only repository architecture, commands, exceptions, and component facts in the effective repository.
Update an existing rule instead of adding a near-duplicate.
Do not record implementation history, reviewer identity, or a description of the fixed bug.
Do not change instruction files when the review contains no new durable lesson.

## Pair pull requests

Every effective pull request must declare the retrospective result.
The organization pull-request template supplies only this declaration and does not replace the `session-retro` skill when drafting the description.

When durable shared guidance changes:

1. Create or update a branch and pull request in `ricochet-rs/agent-instructions`.
2. Make the instructions pull request ready for review before the effective pull request can merge.
3. Add this exact trailer on its own line to the instructions pull-request body:

```text
Origin-PR: https://github.com/ricochet-rs/<repository>/pull/<number>
```

4. Add this exact trailer on its own line to the effective pull-request body:

```text
Instructions-PR: https://github.com/ricochet-rs/agent-instructions/pull/<number>
```

5. Run the effective repository's paired-instructions check.
6. Update the instructions branch from shared `main` until GitHub reports it mergeable without conflicts.
7. Re-run the check after every update to either pull request.

Do not merge the instructions pull request before the effective code pull request.
When the effective pull request merges, its default-branch CI merges the paired instructions pull request.
If the automatic merge fails, report it immediately and leave the instructions pull request open for recovery.

When the retrospective finds no durable shared guidance, add this exact trailer instead:

```text
Instructions-PR: none
```

Do not omit the trailer.
