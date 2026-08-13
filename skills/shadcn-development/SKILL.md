---
name: shadcn-development
description: Build, modify, debug, or update shadcn interfaces in Ricochet TypeScript applications. Use when a repository contains components.json or a task involves shadcn components, registries, presets, forms, dialogs, loading states, or component composition.
---

# Develop shadcn interfaces

Read and follow `typescript-development` alongside this skill.

## Inspect the project

Run `bunx --bun shadcn@latest info --json` before selecting components.
Use the reported framework, component base, aliases, icon library, Tailwind version, and installed components instead of assuming defaults.
Preserve the project's existing visual system and component conventions.

## Select components

Use installed components before adding dependencies or writing custom primitives.
Search configured registries with `bunx --bun shadcn@latest search` when no installed component fits.
Ask which registry to use when the request does not identify one.
Fetch current component guidance with `bunx --bun shadcn@latest docs <component>` before implementing or debugging it.

Compose interfaces from shadcn components rather than recreating their behavior with styled elements.
Use `Dialog` or `AlertDialog` for confirmations.
Use `Skeleton`, `Spinner`, or the project's established progress component for asynchronous loading states.
Use semantic theme tokens rather than raw palette colors.

## Preserve composition and accessibility

Include a title in every dialog, sheet, and drawer, using a visually hidden title when appropriate.
Keep triggers and items inside the groups required by their component API.
Provide `AvatarFallback` with every avatar.
Connect validation state to both the field container and its form control.
Use the project's component variants and icon conventions before adding custom classes.

## Add or update components

Use Bun for every shadcn command and dependency change.
Inspect installed components before running `bunx --bun shadcn@latest add`.
Preview updates with `--dry-run` and inspect each affected file with `--diff`.
Preserve local changes when applying upstream updates.
Do not use `--overwrite` unless the user explicitly authorizes replacing local component files.
Read every added or updated file and correct imports, aliases, icons, composition, and accessibility before continuing.

## Validate

Run the repository formatter, linter, type checker, and relevant tests through its existing `just` or Bun commands.
Exercise the affected interaction when browser or component tests are available.
