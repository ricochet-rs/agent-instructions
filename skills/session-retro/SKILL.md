---
name: session-retro
description: Capture hard-won, reusable development lessons before opening a pull request or after a non-trivial session. Use when preparing a PR description or wrapping up work that exposed surprising repository behavior, failed approaches, or missing guidance.
---

# Session retrospective

Review the session, final diff, failed attempts, corrections, and validation results before drafting the pull request description.

## Select lessons

Keep a lesson only when all of these are true:

1. A future session could encounter the same situation.
2. The correct behavior was not already obvious from repository instructions or tooling.
3. The lesson can be expressed as a present-tense rule rather than session history.

Do not turn implementation details, one-off failures, or the PR summary into instructions.
Write nothing when the session produced no durable lesson.
Omit the `Instructions-PR:` trailer from the effective pull-request body when no shared instruction change is needed.

## Record lessons

Place each rule in the closest applicable `CLAUDE.md` or `AGENTS.md`.
Prefer updating an existing rule over adding another formulation.
Keep repository-specific facts in the repository and reusable organization guidance in the shared instruction repository.
Ensure every modified instruction remains true after the code change.

After the retrospective, draft the PR description from the final diff and validation evidence.
Treat pull-request templates as workflow metadata only, not as authority for the description's headings, structure, or wording.
When shared guidance changed, include the paired instructions pull-request URL using the exact `Instructions-PR:` trailer required by `digesting-review-feedback`.

## Format the description

Start with exactly one standalone sentence summarizing the change and its outcome.
Do not put a heading before this sentence.

Put all supporting explanation, material changes, and validation evidence in a collapsed details block using this exact structure:

```markdown
One-sentence summary.

<details>
<summary>AI Summary</summary>

Supporting details and validation evidence.

</details>
```

Add the `Instructions-PR:` trailer below the details block only when a paired instructions pull request exists.
Keep workflow trailers outside the details block, each on its own line.
When handing a description to a person instead of writing it directly, provide the raw Markdown in a fenced block so it can be pasted unchanged.
