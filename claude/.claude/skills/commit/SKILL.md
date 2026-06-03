---
name: commit
description: Create a git commit for the pending changes using conventional-commit + gitmoji format. Use when the user asks to commit, stage and commit, or save work to git.
---

# Commit

Create a well-formed git commit for the current logical unit of work.

## Steps

1. **Survey ALL changes.** Run `git status` (the only one of these that shows untracked
   files), plus `git diff --staged` and `git diff` (unstaged). Also `git log --oneline -5`
   to match the repo's message style. `git diff` alone misses new untracked files — always
   include `git status`.
2. **Scope to one logical unit.** A commit captures a complete unit of work (a fix AND its
   tests, a feature AND its model changes) — not just the last file touched. Do NOT sweep in
   unrelated changes; if the tree mixes unrelated work, stage only the files for this unit.
3. **Stage.** If nothing is staged, `git add` the files for this change (`git add <file>...`,
   or `git add -p` for partial hunks). Use `git add .` only after confirming every pending
   change belongs to this unit. Include already-generated DB migrations (`db/`) when they are
   part of the change.
4. **Pick type + gitmoji.** Format: `type(scope): <emoji> subject`. Use the table below; for
   anything not listed, look it up in `gitmojis.json` in this skill's directory. Do NOT guess.

   | type     | emoji | when                                   |
   |----------|-------|----------------------------------------|
   | feat     | ✨    | new feature                            |
   | fix      | 🐛    | bug fix                                |
   | fix      | 🚑️   | critical hotfix                        |
   | docs     | 📝    | documentation                          |
   | style    | 🎨    | structure/format, no behavior change   |
   | refactor | ♻️    | restructure, no behavior change        |
   | perf     | ⚡️    | performance                            |
   | test     | ✅    | add / update / pass tests              |
   | build    | 📦    | build system or dependencies           |
   | ci       | 👷    | CI configuration                       |
   | chore    | 🔧    | config / tooling                       |
   | revert   | ⏪️   | revert a previous change               |
   | remove   | 🔥    | remove code or files                   |
   | security | 🔒️   | fix security / privacy issue           |

5. **Write the message.** Subject under 72 chars, imperative mood. Add a body (blank line,
   then bullets) only when the *why* isn't obvious from the subject.
   Example: `fix(appointments): 🐛 calculate duration from the selected service`.
6. **Guardrails.**
   - NEVER add `Co-authored-by` lines or any "Generated with Claude Code" / AI attribution.
   - Do NOT edit `CHANGELOG.md` or bump version numbers — CI/CD generates both on merge to `main`.
   - Do NOT commit secrets, credentials, or large build artifacts — flag them instead.
   - Do NOT use `--no-verify`; respect pre-commit hooks.
7. **Commit.** Run `git commit -m "<message>"` (use a HEREDOC for a multi-line body).
8. **Handle hook outcomes.** If a pre-commit hook fails, read its output and fix the cause —
   do not bypass it. If a hook modified files (formatter/linter), `git add` the changes and
   re-commit. Confirm with `git status`.
