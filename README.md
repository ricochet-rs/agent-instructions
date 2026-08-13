# Ricochet agent instructions

This private repository is the canonical source for shared agent instructions and workflow skills used by `ricochet-rs` repositories.

Repository-specific instructions remain in each consuming repository.
The templates in `templates/` synchronize this repository to `origin/main`, load the global instructions, and select the relevant workflow skills.

## Pilot installation

Copy the applicable template into a consuming repository.
Keep existing repository-specific instructions below the template's repository section.

An agent must stop before modifying the consuming repository when it cannot authenticate to GitHub, synchronize `origin/main`, or validate the required files.

The repository is private during the pilot, so contributors need access to the `ricochet-rs` organization and authenticated GitHub SSH access.
