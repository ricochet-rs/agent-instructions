---
name: user-facing-docs
description: Write anything a user reads, including documentation pages, release notes, UI labels, and error messages. Use when writing or editing documentation, drafting release notes, or writing a string that ships to users. Applies Smart Brevity, caps titles at 40 characters, and bans internal implementation detail.
---

# User-facing docs

Applies to every string a user reads.
Documentation pages, release notes, UI labels, error messages, onboarding mail.

## Know the reader

Two readers, and the data scientist wins every tie.

- **Data scientist** who writes R, Julia, Python, or a mix, and wants their own work deployed and running.
- **Admin** who runs the server and keeps the instance installed, configured, and up.

Both are semi-technical.
Assume a terminal, git, and fluency in their own language's tooling, and never explain those.

Answer three questions before the first line:

- What does this reader want to do?
- What do they already know?
- What is the one thing they must remember?

The data scientist's goal is their own work, never our software.
Write "deploy your Shiny app" rather than "use the deployment pipeline".
A sentence that serves only the admin belongs on an admin page.

## Never describe the internals

The reader bought a product, not the repository.
Cut any sentence naming something the reader cannot type, click, or configure:

- Crate, package, module, type, and function names
- Build commands, task runners, and feature flags
- Table names, columns, migrations, and SQL
- Source paths, branch names, and pull request numbers
- Environment variables outside the documented configuration surface
- The bug that existed, the refactor that fixed it, and why either happened
- Roadmap, team process, and what the team plans next

Never write from your own use of the product.
A development build, a seeded fixture, a test app, and a local watch loop are not the reader's situation.
If the only way you know a behavior is by reading the source, the reader has no way to act on it.

Rewrite toward what the reader does and sees:

| Internal                                       | User-facing                                 |
| ---------------------------------------------- | ------------------------------------------- |
| The request is routed to a worker process      | Your app receives the request               |
| A table stores the retention rule per item     | Each item has a retention policy            |
| Startup aborts when the key file is missing    | The server stops and reports a missing key  |
| Fixed a race in the leader lease               | Scheduled tasks no longer run twice         |
| Run the dev watch task and open the page       | Open **Settings** and select **Scheduling** |

## Lead with the action

- Put a runnable command or a click path in the first screen.
- Open with one sentence saying what the reader gets.
- Move background below the action, or delete it.
- Answer "what is this" and "why does it matter to me" before anything else.

## Titles

40 characters is the hard cap and 30 is the target.
Name the task or the thing, never the article about it.

| Too long                                      | Better               |
| --------------------------------------------- | -------------------- |
| Understanding How Deployment Retention Works  | Deployment Retention |
| A Guide to Configuring Your Execution Backend | Execution Backend    |
| Everything You Need to Know About API Keys    | API Keys             |

- No colon subtitles.
- No "Understanding", "Introduction to", or "Getting Started With".
- Match the capitalization already used in the surrounding section.

## Structure

Order headings by how the reader moves, not by how the system is built.

1. What the reader gets, in one sentence
2. The command or the steps
3. Options and variations
4. What to do when it fails
5. Where to go next

- Prefer a list to a paragraph.
- Three sentences is a long paragraph.
- One callout at a time, never two in a row.
- Bold a literal UI label or command, and nothing else.
- Use inline code for anything the reader types.
- Use italics rarely, for a single word of emphasis.
- At most one emoji per page, and never in a heading 👍

## Write like a person

- Second person, present tense, active voice.
- Short words beat long ones.
- Say what happens, not what is designed to happen.
- Give the number, the limit, or the default instead of calling something configurable.

Banned punctuation and phrasing:

- Em dash and semicolon
- "No x, no y, just z" and every other rule-of-three flourish
- "It is not just x, it is y"
- "Seamlessly", "robust", "leverage", "unlock", "supercharge", "delve", "game-changer"
- "Simply", "just", "easily", "obviously", "of course"
- Openers such as "In this guide", and closers that summarize what the reader read

## Stop

- Write the page, then cut a third of it.
- A sentence that survives only because it is true is still cut.
- End on the last useful instruction.

## Before submitting

- [ ] The page names which of the two readers it serves
- [ ] Title is 40 characters or fewer
- [ ] The first screen contains the action
- [ ] No package, table, flag, source path, or function name appears
- [ ] No em dash and no semicolon
- [ ] Every bullet earns its line
- [ ] Release notes also follow the release-note rules in [global instructions](../../instructions/global.md)
