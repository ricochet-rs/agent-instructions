---
name: digesting-review-feedback
description: Apply human pull-request review feedback and preserve its durable lessons in the closest repository instruction file. Use after changes are requested, a batch of inline comments arrives, or a reviewer identifies an over-engineered or incorrect approach.
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
Place each rule in the closest applicable `CLAUDE.md` or `AGENTS.md`.
Update an existing rule instead of adding a near-duplicate.
Do not record implementation history, reviewer identity, or a description of the fixed bug.
Do not change instruction files when the review contains no new durable lesson.
