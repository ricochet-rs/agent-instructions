---
name: demo-capture
description: Record a user-visible change as screenshots or an annotated GIF from a locally running build. Use when a reviewer, an issue, or a customer needs to see a behavior change rather than read a description of it, and when a claim about the interface should be backed by evidence.
---

# Demo capture

Capture the change from a build you started yourself.
Never assemble a demo from memory, from a design mockup, or from a page you did not load.

Start the application using the owning repository's own instructions.
Keep repository-specific build commands in that repository, not in this skill.

## Confirm the build under the browser

A stale asset bundle produces a demo of the previous behavior that looks exactly like a correct one.
Before capturing, confirm that the page loaded the build you just produced, for example by comparing the hashed asset names in the served HTML against the build output.

Capture only after that check passes.
Treat any drift as a failed capture rather than an interesting anomaly.

## Prefer discrete frames over video

Assemble a GIF from deliberate screenshots instead of recording a session.
Frames stay legible, keep the file small, and let each step carry a caption.

Use a fixed viewport and device scale factor for every frame so they align when animated.
Pad frames to a common height rather than letting the animation jump.

Headless screenshots contain no address bar, so render the URL into a caption strip above each frame when the change is about navigation or routing.

## Show the whole path, including what is simulated

Capture the before state as well as the after state when the point is a change in behavior.
The before state is what makes the after state legible.

Local demos usually contain a stand-in: seeded database rows, a mock identity provider, an application with no real deployment.
Caption every stand-in in the frame where it appears.
An unlabeled stand-in turns a demo into a false claim about a working system.

Stop and say so when a step cannot be captured honestly.
A demo that skips the step a reviewer cares about is worth less than a sentence admitting the gap.

## Name and publish

Name each file for the work it documents, such as `1300-flow.gif`.
Publish with [asset-sharing](../asset-sharing/SKILL.md) and reference the returned link from the issue or pull request.

Review each frame before publishing.
Screenshots of a running instance routinely contain customer names, tokens in a URL, log output, and internal hostnames.
