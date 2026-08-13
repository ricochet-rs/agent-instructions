# Ricochet agent instructions

This private repository is the canonical source for shared agent instructions and workflow skills used by `ricochet-rs` repositories.

Repository-specific instructions remain in each consuming repository.
The templates in `templates/` bootstrap this repository at the immutable commit stored in `.agent-instructions-version`, load the global instructions, and select the relevant workflow skills.

## Pilot installation

Copy the templates into a consuming repository and replace the version placeholder with an immutable commit from this repository.
Keep existing repository-specific instructions below the template's repository section.

An agent must stop before modifying the consuming repository when it cannot authenticate to GitHub, obtain the pinned revision, or validate the required files.

The repository is private during the pilot, so contributors need access to the `ricochet-rs` organization and authenticated GitHub SSH access.
