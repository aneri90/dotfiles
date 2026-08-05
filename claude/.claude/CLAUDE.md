# Global Instructions

## Repository layout

- All company repos live in `~/gitlab-src/**`, hosted on GitLab Ultimate SaaS (gitlab.com).
- Microservices and services use trunk-based development: `main` is the trunk, work happens on feature branches merged via MRs.
- Some IaC repos instead use one branch per environment (e.g. `test`/`main`).

## Cloud & IaC

- Google Cloud (`gcloud`) and Azure (`az` CLI) are the cloud providers.
- Terraform is the IaC tool, managed via GitLab CI/CD pipelines to propagate infrastructure changes. Never run `terraform plan` or `terraform apply` locally — let the pipeline handle it.

## Code style

- Comment sparingly — match the surrounding file's existing comment density.
- Comment the *why* (constraint, workaround, gotcha), never the *what*. No comments that restate the code.
- No banner/separator comments, no ASCII dividers, no all-caps emphasis (`IMPORTANT:`, `CRITICAL:`, `NOTE:`) unless a real footgun warrants it.
- No comments narrating the edit ("added X", "changed Y", "now handles Z") — that belongs in the commit message.
- Docstrings/doc-comments only where the file or language convention already uses them.

## Git workflow

- Pull incoming changes before starting work.
- Use conventional commits (semantic versioning).
- Do not add Co-authored-by trailers.
- Do not add Generated with Claude Code (or similar) to any commit / issue / merge requests
- Do not edit `CHANGELOG.md` or bump version numbers manually — both are produced automatically by CI/CD on merge to `main`.

## Working in git worktrees

- Edits often land in the main repo by mistake: `Edit`/`Write` need absolute paths, and the model tends to build them from main-repo paths seen during earlier `Read`/exploration or from the reported "Primary working directory" — which may point at the main repo, not the worktree.
- Detect a worktree session when the working directory is under `.claude/worktrees/`, or when `git rev-parse --git-dir` differs from `git rev-parse --git-common-dir`.
- In a worktree, treat the worktree root as the base for ALL file operations. Get it with `git rev-parse --show-toplevel` — do not trust the env "Primary working directory".
- Build every absolute `Edit`/`Write` path from that worktree root. Never reuse a main-repo absolute path. If you `Read` a file at a main-repo path earlier, re-resolve it under the worktree root before editing.
- Run `pwd` before the first edit to confirm you are in the worktree, and keep the main repo's working tree clean.
