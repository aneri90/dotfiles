---
name: polish
description: Run once on the branch diff right before committing code, to tighten names, comments and small structure. Skip docs-only, tests-only and config-only changes, and diffs under ~20 changed lines.
---

Polish only what this branch changed. Never touch code outside the diff, and never change behavior.

1. Get the scope: `git diff $(git merge-base HEAD origin/HEAD 2>/dev/null || git merge-base HEAD origin/main)` plus staged and unstaged changes. If the diff is docs, tests or config only, or under ~20 changed lines, stop and say so.
2. Check the changed lines against the rules below and the "Code style" section of the global CLAUDE.md (comments: why, never what; no narration, no banners).
3. Apply at most ~10 edits. List anything larger (a split, a merge of modules) as a finding instead of doing it.
4. Run the checks the repo already has for the touched files (tests, linter, type checker).
5. Report: the edits made, the findings left, and the check results.

## Names

- One word per concept, one concept per word. If `sync` already means "pull remote changes", it cannot also mean "flush to disk".
- Cut words the context already carries: in `workspaceWatcher`, `watchWorkspace` beats `startNativeWorkspaceWatcher`.
- A long compound name is usually a hedge: `baseline`, not `lastObservedDiskContent`.
- Prefer short, plain words to Latinate jargon: `prune`, `drop`, `watch` over `reconcile`, `coalesce`, `normalize`.

## Structure (small moves only)

- Lead with the exported or important functions; helpers go below.
- Use the codebase's existing helpers instead of inlining a new one.
- Drop derived state: a value computable from what is in scope is not passed or stored (an `isDirty` that always equals `content !== baseline` goes).
- Merge two types, functions or constants that overlap almost completely.

## Overfitting

- A name or comment that only makes sense to someone who watched this session gets rewritten in the codebase's own words.
- No backwards compatibility with code that never shipped: delete the old signature, alias or shape from earlier in the same branch and update its callers.
