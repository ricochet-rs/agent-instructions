# Ricochet agent instructions

This public repository is the canonical source for shared agent instructions and workflow skills used by `ricochet-rs` repositories.

Repository-specific instructions remain in each consuming repository.
The templates in `templates/` synchronize this repository to `origin/main`, load the global instructions, and select the relevant workflow skills.
The CI templates load the paired-instructions guard from this repository at runtime so guard fixes remain centralized.

## Pilot installation

Copy the applicable template into a consuming repository.
Keep existing repository-specific instructions below the template's repository section.
Merge `templates/claude-settings.json` into the consuming repository's `.claude/settings.json`, so Claude Code synchronizes and loads the global instructions once per session instead of fetching them on every request.

An agent must stop before modifying the consuming repository when it cannot synchronize `origin/main` or validate the required files.
