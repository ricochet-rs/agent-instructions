---
name: design-mockups
description: Mock up a screen in FigCraft before coding it, then take the chosen layout into a ricochet-rs repository. Use when a change reshapes a page or component and its layout is still open, when a review asks for a different arrangement, when a .figcraft file is opened, built, checked or exported, when the `figcraft` MCP tools or `figcraft-cli` come up, or when someone wants to watch a design take shape live.
---

# Design mockups

FigCraft is a layout and interface design tool with an MCP server, so an agent can build real frames, components and variants instead of describing them.
Use it to try two or three layouts of a screen before writing code, to check a layout against the design system, and to give reviewers something concrete to look at.

## Where designs live

Every ricochet design lives in the `ricochet/ui-design` repository on codefloe.com, never in a code repository.

- `library/ricochet-library.figcraft` holds the variables, text styles, effect styles and components that every design starts from.
- `design-system.md` states the visual rules, and `design-lint.toml` encodes the checkable ones for the lint.
- `server/` holds mockups for the server UI in `ricochet-ui`, `cloud/` holds the cloud console, and `web/` holds ricochet.rs.

Read the `CLAUDE.md` of `ui-design` before the first write, because it holds the library workflow and the copy rules.
Clone it next to the code repository when it is missing, and ask before committing or pushing to it.

## Connect

FigCraft runs either as a desktop app that the MCP attaches to, or headless where no display exists.

- On a machine with a display, start the app from `ui-design` with `just figcraft`, then attach with `figcraft-cli mcp --attach 7980`.
- On a machine without a display, run `figcraft-cli mcp` with `--automation-write-root` and `--automation-read-root` covering the design repository and the code it reads.
- The automation roots refuse every path outside them and switch off every network command, including `collab.host`.
- A server added mid-session needs a restart of the agent before its tools load.
- `figcraft-cli run --in <file> <steps.json>` runs commands against a file without the MCP, one JSON result per line, which suits scripts.

## Build

- Run `inspect_document` before the first write and after any pause, and confirm `path` names your file.
- In each new file, run `library.add` with the library path, then place parts with `library.import` and `instance.create`.
- Set variants and text with `instance.setProperties`, and never redraw a part the library has.
- Bind every fill, stroke and effect color to a library variable with `library.bindVariable`.
- Apply text styles with `library.applyStyle` instead of setting font and size by hand.
- Bind a fill to every new text layer, because text created without one turns white on a dark page.
- Set the text on every new instance, because it shows the component set's default text rather than its variant's.
- Change the main component to move, resize or add layers, because an instance refuses edits outside its slots.
- For dark mode, duplicate the frame and run `library.setVariableMode` with the `Dark` mode instead of recoloring.
- Build one tree level per `batch` when you need to read the new ids back.
- After `edit.duplicate` on a frame, compute a copy's ids as `original + (copy root - original root)` and check one with `get_node`.
- Keep `get_node` at depth 0 or 1, or save its output and query it with `jq`, because a deep dump overflows.
- Give a frame that should fit its content hug sizing on the frame and its rows, because fill-height children inside a hug parent collapse to zero.
- Inspect the document before retrying a call that failed with a transport error, because it may still have run.
- Build one complete frame, screenshot it and fix it, then duplicate it for the other states and change only what differs.

## Check

Look at every frame with `screenshot`, and `export` a 2x PNG for anything a person or reviewer will see.
Share those PNGs by following `skills/asset-sharing/SKILL.md`.

Lint a file without opening the app:

```sh
# reads the nearest design-lint.toml above the file
~/.cache/ricochet-rs/agent-instructions/skills/design-mockups/scripts/design_lint.py path/to/file.figcraft -v
# a machine-readable score, for example inside a review loop
design_lint.py --json path/to/file.figcraft
```

Errors cover unbound colors, unstyled text and effects, off-system fonts, banned copy and, with `sharp_corners = true`, rounded corners.
Warnings cover low contrast and copy a person should read.
Without a config only the em dash and spaced en dash rules apply.
The `design-lint.toml` in `ui-design` shows every key: `fonts`, `mono_fonts`, `ignored_frame_prefixes`, `sharp_corners`, and `[[copy]]` rules with `rule`, `pattern`, `severity`, `message`, `ignore_case` and `mono`.
Frames whose names start with "Audit" are exploration work, and the lint skips them.

## Live sessions

Someone can watch a design live in a browser and in the FigCraft app at the same time.

1. Host the file from an MCP process without automation roots, which may run network commands:

   ```sh
   # prints HOST with the figcraft://join link, then the peer count every 30 seconds
   python3 ~/.cache/ricochet-rs/agent-instructions/skills/design-mockups/scripts/live_host.py <file.figcraft> <private address> 120
   ```

2. Bind it to a private network address such as a tailnet address, never a public one.
3. Open the `figcraft://join` link in the FigCraft app, or serve the FigCraft web build and open `http://<address>:<port>/#join=<url-encoded figcraft://join link>`.

The hosted copy is not saved to disk, so save deliberately before stopping the host.
Never run `collab.share` with its default `via: "online"`, because that uploads the file to the public server `collab.craftapps.dev`.

## From mockup to code

ricochet-rs/ricochet#1899 followed this loop from a review comment to the row of figures it ships.

1. Read the screen's current code and capture it, so the mockup starts from what exists.
2. Build two or three variants from the library, each a complete frame, and lint them.
3. Show the variants to the person who asked and let them choose.
4. Implement the chosen variant with the target repository's own components and tokens, never by copying values out of FigCraft.
5. Capture the real page in each state by following `skills/demo-capture/SKILL.md`, and compare it with the mockup before claiming it matches.
6. Commit the mockup to `ui-design` and link it from the pull request description.
