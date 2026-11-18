# Global Instructions

## Repository layout

- All company repos live in `~/gitlab-src/**`, hosted on GitLab Ultimate SaaS (gitlab.com).
- Microservices and services use trunk-based development: `main` is the trunk, work happens on feature branches merged via MRs.
- Some IaC repos instead use one branch per environment (e.g. `test`/`main`). Those repos are named after this convention `<applicazion>-iac` and `<applicazion>-deploy`.
- `<applicazion>-iac` and `<applicazion>-deploy` usually have test as default branch and keep their environment updated by branch promotion. Test and prod values coexists in the same branch. When merging test/main branches the relative environment values get selected by the CICD.

## Cloud & IaC

- Google Cloud (`gcloud`) and Azure (`az` CLI) are the cloud providers.
- Terraform is the IaC tool, managed via GitLab CI/CD pipelines to propagate infrastructure changes. Never run `terraform plan` or `terraform apply` locally — let the pipeline handle it.

## Code style

- Comment the *why* (constraint, workaround, gotcha), never the *what*. No comments that restate the code.
- No banner/separator comments, no ASCII dividers, no all-caps emphasis (`IMPORTANT:`, `CRITICAL:`, `NOTE:`) unless a real footgun warrants it.
- No comments narrating the edit ("added X", "changed Y", "now handles Z") — that belongs in the commit message.
- No comments referencing epics / phases / sprint. Document the intent of the code if its necessary.

## Git workflow

- Pull incoming changes before starting work.
- Use conventional commits (semantic versioning).
- Do not add Generated with Claude Code (or similar) to issues or comments
- Do not edit `CHANGELOG.md` or bump version numbers manually — both are produced automatically by CI/CD on merge to `main`.

## Release and dependencies updates

- Both company internal and external dependencies are handled by RenovateBot
- When we commit on default branch ( main ) the CICD evaluate via semantic release if the commit message should trigger a release version ( via semantic commit convention )
- When a downstream project depends on a released repo -> the CICD are configured for triggering Renovate to automatically update via MR
- Renovatebot will automatically create MR for minor and patch versions. Major version are configured to be manually approved by user in a Dependency Dashboard issue.


## Working in git worktrees

- Edits often land in the main repo by mistake: `Edit`/`Write` need absolute paths, and the model tends to build them from main-repo paths seen during earlier `Read`/exploration or from the reported "Primary working directory" — which may point at the main repo, not the worktree.
- Detect a worktree session when the working directory is under `.claude/worktrees/`, or when `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`.
- In a worktree, treat the worktree root as the base for ALL file operations. Get it with `git rev-parse --show-toplevel` — do not trust the env "Primary working directory".
- Build every absolute `Edit`/`Write` path from that worktree root. Never reuse a main-repo absolute path. If you `Read` a file at a main-repo path earlier, re-resolve it under the worktree root before editing.
- Run `pwd` before the first edit to confirm you are in the worktree, and keep the main repo's working tree clean.

## Shell

- The Bash tool runs bash 5 (`CLAUDE_CODE_SHELL`). If `echo $BASH_VERSION` prints nothing, the session fell back to zsh: quote globs, pipe JSON with `printf '%s'` (not `echo`), write `${TAG}:path`, and never name a variable `path` or `status`.
- Never print environments or files that may hold secrets (`env`, `printenv`, `cat ~/.zshenv`, a pod's env). List names only: `env | cut -d= -f1`.

## Python dependencies

- `uv sync` authenticates to the private index through keyring. Never export an index token, and never reach a library through `PYTHONPATH`.
- In a new worktree, run `uv sync` before any test or import check.
- On a 401, run `keyring get <index-url> oauth2accesstoken`; if that fails, ask the user to run `gcloud auth login`.

## GitLab and deploy waits

- Do not write polling loops. Use `glflow` (`mr-wait`, `mr-merge`, `wait-tag`, `wait-image`, `deploy-bump`); `glflow <cmd> --help` lists the flags.
- Run it with a Bash timeout of 600000 and read the last stdout line as JSON. Exit 3 means still pending: run the same command again. Exit 4 means the head moved, a conflict, or `behind`: read `status` before retrying, and if the new head is your own push, rerun.
- Never use `glab mr merge --auto-merge`; merge with `glflow mr-merge`, which merges only the SHA it saw green.
- Every merge to `main` is followed by a `chore(release)` commit, so the next MR in the same repo falls behind. `mr-merge` rebases it on the server and merges the new green head; it exits 2 (`blocked`) when the MR needs a person (approval, open threads).
- After a release, take the version from `glflow wait-tag --mr <iid>`, never the newest tag.
- A green deploy pipeline is not proof: finish every deploy with `glflow wait-image`.
