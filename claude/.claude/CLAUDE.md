# Global Instructions

## Repository layout

- All company repos live in `~/gitlab-src/**`, hosted on GitLab Ultimate SaaS (gitlab.com).
- Microservices and services use trunk-based development: `main` is the trunk, work happens on feature branches merged via MRs.
- Some IaC repos instead use one branch per environment (e.g. `test`/`main`).

## Cloud & IaC

- Google Cloud (`gcloud`) and Azure (`az` CLI) are the cloud providers.
- Terraform is the IaC tool, managed via GitLab CI/CD pipelines to propagate infrastructure changes. Never run `terraform plan` or `terraform apply` locally — let the pipeline handle it.

## Git workflow

- Pull incoming changes before starting work.
- Use conventional commits (semantic versioning).
- Do not add Co-authored-by trailers.
- Do not add Generated with Claude Code (or similar) to any commit / issue / merge requests
- Do not edit `CHANGELOG.md` or bump version numbers manually — both are produced automatically by CI/CD on merge to `main`.
