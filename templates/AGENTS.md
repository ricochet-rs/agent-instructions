# Required Ricochet instructions

Before inspecting repository files, planning, editing, or running project commands, ensure the shared instructions are available.

1. Read `.agent-instructions-version` from this repository.
2. Use `~/.cache/ricochet-rs/agent-instructions` as the shared checkout.
3. If the checkout is absent, clone `git@github.com:ricochet-rs/agent-instructions.git` there.
4. Fetch the required revision from `origin` and check it out in detached-HEAD mode.
5. Verify that the resolved commit exactly matches the pinned revision.
6. Verify that `instructions/global.md`, `.codex-plugin/plugin.json`, and every selected `SKILL.md` exist.
7. Read `instructions/global.md`.
8. Read and follow `skills/development-flow/SKILL.md` for code changes.
9. Read the applicable language skills according to the repository manifests and files involved.

The shared skills may not appear in the startup skill catalog.
Read their `SKILL.md` files directly from the shared checkout and follow them for the current session.

If authentication, synchronization, revision checkout, or validation fails, stop before modifying the repository and report the failure clearly.
Do not silently continue with missing or stale shared instructions.

# Repository instructions

Add repository-specific architecture, commands, and exceptions here.
