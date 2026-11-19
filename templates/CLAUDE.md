# Required Ricochet instructions

Synchronize the shared instructions once per session, before the first repository work.
Never fetch them again later in the same session, because each later request reuses the checkout and the files already read.

When the session context already contains "Shared ricochet-rs instructions synchronized to", the `SessionStart` hook in `.claude/settings.json` has synchronized the checkout and loaded `instructions/global.md`, so skip synchronizing and re-reading it and continue with the skill reads.
Otherwise, synchronize manually:

1. If `~/.cache/ricochet-rs/agent-instructions` is absent, clone `https://github.com/ricochet-rs/agent-instructions.git` there.
2. Run `sh ~/.cache/ricochet-rs/agent-instructions/scripts/bootstrap.sh`, which checks out `origin/main` and verifies the required files.
3. Read `instructions/global.md`.
4. Read the applicable language skills according to the repository manifests and files involved.
5. Read and follow `skills/user-facing-docs/SKILL.md` before writing documentation, release notes, or other text a user reads.
6. Read and follow `skills/demo-capture/SKILL.md` before recording a user-visible change, and `skills/asset-sharing/SKILL.md` before sharing the result.

The shared skills may not appear in the startup skill catalog.
Read their `SKILL.md` files directly from the shared checkout when a step first needs them, and do not re-read a file already read in this session.

If authentication, synchronization, HEAD validation, or a required read fails, stop before modifying the repository and report the failure clearly.
Do not silently continue with missing or stale shared instructions.

# Repository instructions

Add repository-specific architecture, commands, and exceptions here.
