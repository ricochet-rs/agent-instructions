---
name: ricochet-repository-map
description: Identify repository ownership and dependency chains across the Ricochet product, CLI, documentation, deployment, infrastructure, and SaaS repositories. Use when a Ricochet task spans repositories, when the current repository may not own the requested change, or when tracing how an artifact reaches a deployment.
---

# Navigate Ricochet repositories

Read [references/repositories.md](references/repositories.md) before selecting repositories or planning a cross-repository change.

## Locate ownership

1. Identify the user-visible behavior or deployed artifact involved.
2. Use the reference to select the smallest likely set of owning repositories.
3. Inspect each selected repository's remote and local instructions before acting.
4. Verify ownership in current manifests, workflow files, image references, or deployment configuration.
5. Treat the reference as a routing aid rather than a source of truth when current repository content disagrees.

Do not broaden a task to adjacent repositories merely because they appear in the same dependency chain.
Do not change a downstream deployment repository unless the requested behavior requires a deployment or version update.
Keep repository-specific architecture and commands in their owning repositories.

## Work across repositories

State which repository owns each planned change.
Apply and validate one coherent repository change at a time.
Use each repository's own validation commands.
Report any dependent repository change that remains required but is outside the available checkout or user-authorized scope.
