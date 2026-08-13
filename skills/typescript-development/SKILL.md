---
name: typescript-development
description: Apply ricochet-rs JavaScript and TypeScript package, UI, formatting, and validation conventions when changing package manifests, frontend code, Bun scripts, or tests.
---

# TypeScript development

Use Bun for dependency management and scripts.
Do not use npm, Yarn, or pnpm.
Preserve the repository's existing framework and component system.
Use the existing shadcn `Dialog` component for confirmations.
Do not use browser `confirm()` or `alert()`.
Show a visible loading state during asynchronous operations.

Run the repository formatter, linter, type checker, and tests through existing `just` or Bun scripts.
Do not introduce a new package-management lockfile.
