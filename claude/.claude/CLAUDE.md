# Global Instructions

## Repository layout

- All company repos live in `~/gitlab-src/**`, hosted on GitLab Ultimate SaaS (gitlab.com).
- Trunk-based development: `main` is the trunk, work happens on feature branches merged via MRs.
- Some IaC repos use one branch per environment (e.g. `test`/`main`).

## Cloud & IaC

- Google Cloud (`gcloud`) and Azure (`az` CLI) are the cloud providers.
- Terraform is the IaC tool, managed via GitLab CI/CD pipelines to propagate infrastructure changes.

## Git workflow

- Pull incoming changes before starting work.
- Use conventional commits (semantic versioning).
- Do not add Co-authored-by trailers.
