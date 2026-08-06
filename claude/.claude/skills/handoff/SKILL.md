---
name: handoff
description: Snapshot the current session into a handover prompt — goal, state, decisions, gotchas, next steps — written to ~/.claude/handoffs/ and printed for copy-paste, so the session can be cleared and resumed fresh without losing context.
disable-model-invocation: true
allowed-tools: Read, Write, Bash
argument-hint: "[optional focus, e.g. 'only the migration work']"
---

# Session handoff

Distill the current session into a self-contained handover prompt, so the user can `/clear`
and resume in a fresh session without losing the thread. Write it to a file *and* print it —
the file survives even if the terminal scrollback does not.

`$ARGUMENTS`, if given, narrows the handoff to that topic or workstream. Otherwise cover the
whole session.

## 1. Gather ground truth

Do not trust conversational memory of repo state — earlier messages may describe files that
have since changed. If the session is inside a git repo, run:

```sh
git rev-parse --show-toplevel
git status --short
git log --oneline -5
git diff --stat
```

Note whether this is a worktree (`git rev-parse --git-dir` differs from
`git rev-parse --git-common-dir`) and record the worktree path if so. If there is no repo,
skip this and drop the Repo state section.

## 2. Extract from the session

Review the full conversation and pull out:

- **Goal** — the original ask, and how it evolved if it did.
- **Done** — split *verified* (tests ran, output actually seen) from *unverified* (edits made
  but never exercised). Never promote unverified work to verified.
- **In progress** — half-finished edits, pending decisions, anything mid-flight.
- **Decisions** — each key decision *and why it was made*, so the fresh session does not
  relitigate it.
- **Gotchas / dead ends** — approaches tried and abandoned, surprising constraints, commands
  that failed and why. This is the most valuable and most easily lost content.
- **Next steps** — an ordered list, each step concrete enough to act on with zero memory of
  this session.
- **Pointers** — file paths (`path:line`), commands, URLs, branch names, ticket IDs.

## 3. Write the handoff file

Write to `~/.claude/handoffs/<YYYY-MM-DD>-<kebab-slug>.md` (create the directory if missing;
slug from the task title). Use this template, dropping any section with nothing to say —
never leave a heading empty:

```markdown
# Handoff: <task title>

## Goal

## Repo state
<repo path, branch, worktree?, dirty files, last commit>

## Done
- (verified) …
- (unverified) …

## In progress

## Decisions
- <decision> — <why>

## Gotchas / dead ends

## Next steps
1. …

## Pointers
```

## 4. Print the handover

Print the same content in a fenced code block, then exactly these two resume options:

1. Run `/clear`, then paste the block above.
2. Run `/clear`, then send: `Read ~/.claude/handoffs/<file> and continue from its next steps.`

## Guardrails

- Only facts from this session and from the git commands in §1 — never invent state, results,
  or file paths.
- Self-contained: assume the reader has zero context. No session-local shorthand, no "as
  discussed above".
- Convert relative dates ("today", "yesterday") to absolute dates.
- Write nothing inside the project repo; the only file written is the handoff under
  `~/.claude/handoffs/`.
- Do not commit, and do not run `/clear` yourself.
