1. Run `git diff --staged` and `git diff` (unstaged) to see ALL pending changes in the working tree
2. Consider ALL changes holistically — the commit should capture the complete logical unit of work (e.g., a bug fix AND its tests, a feature AND its model changes), not just the last file you touched
3. If nothing is staged, stage all related changes. Use `git add <file>...` for specific files or `git add -p` interactively. Do NOT leave out files that are part of the same logical change. If all files have to be added, use `git add .` instead. Note: if database migrations (`db/` directory) were already generated and are part of the same logical change, include them in the commit.
4. Write a commit message using conventional commit+gitmoji format (e.g., "fix(appointments): 🐛 correctly calculate appointment duration based on service"). Select the gitmoji by looking up the correct one from `gitmojis.json` in this skill's directory — do NOT guess
5. NEVER add Co-authored-by lines
6. Keep the message concise — subject line under 72 chars
7. Run `git commit -m "<message>"`