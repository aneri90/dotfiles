---
name: upgrade-deps
description: Plan and run a researched dependency upgrade for the current project — inventory, changelog and breaking-change research, compatibility gates, preliminary refactors — then execute it MR by MR after approval.
disable-model-invocation: true
argument-hint: "[optional: package names, e.g. 'spring-boot jhipster', or 'all']"
---

# Dependency upgrade

Upgrade the dependencies of the current project without surprises. The output of the first
pass is a **plan** backed by release notes and a codebase impact scan. Nothing is edited until
the user approves it.

`$ARGUMENTS`, if given, limits the scope to those packages (and whatever they drag along,
e.g. a BOM). Otherwise cover every outdated dependency.

## 1. Sync and detect

- `git pull` on the default branch. In a worktree, resolve paths from `git rev-parse --show-toplevel`.
- Detect ecosystems from manifests: `pom.xml`/`build.gradle*`, `package.json` + lockfile,
  `go.mod`, `pyproject.toml`/`requirements*.txt`, `Chart.yaml`, `Dockerfile*`,
  `docker-compose*.yml`, Terraform `required_providers`, CI images in `.gitlab-ci.yml`.
- Read the Renovate config (`renovate.json`, `.gitlab/renovate.json`, `.renovaterc*`) and
  what it `extends`. Packages with `enabled: false` or blocked update types are exactly the
  ones that drift — they are the core of the manual upgrade. Ask why a package is disabled
  if the reason is not obvious; the block may be deliberate (e.g. matching a prod server version).

## 2. Inventory

Build a table: dependency, current, latest stable, update kind (major/minor/patch), source.

- Renovate Dependency Dashboard: `glab issue list --search "Dependency Dashboard"`, then
  `glab issue view <id>` — pending approvals (majors) and detected versions.
- Open Renovate MRs: `glab mr list --author renovate-bot` (or the group bot user).
- Registries for Renovate-disabled packages: Maven Central
  `https://repo1.maven.org/maven2/<group/path>/<artifact>/maven-metadata.xml`, `npm view <pkg> versions`,
  `go list -m -u all`, `pip index versions <pkg>`, container registry tags.
  Filter out pre-releases (`M`, `RC`, `alpha`, `beta`, `CR`, `SNAPSHOT`).
- BOM/parent-managed stacks (Spring Boot, Quarkus, Angular, …): diff the managed versions
  between old and new BOM (e.g. `spring-boot-dependencies-<v>.pom` properties) so transitive
  jumps (Hibernate, Jackson, Liquibase, …) are visible and researched too.

## 3. Compatibility gates

Before choosing a target, check the official compat matrices:

- Framework ↔ framework (Spring Cloud release train ↔ Boot, Nx ↔ Angular, …).
- Runtime minimums (JDK, Node, Go, Python) vs the CI image and the runtime `Dockerfile`.
- Client library ↔ the **production** server (DB, Redis, Elasticsearch, Kafka). Look up the
  prod tier/version (cloud CLI read-only, helm values, memory) — the local compose image
  should match prod, not be ahead of it.

If a gate blocks, pick the highest compatible version and record the blocker with its source.

## 4. Opinionated frameworks (JHipster and similar)

Frameworks that pin the underlying stack need extra checks:

- **Respect the pin.** Use the stack version the framework declares. JHipster declares Spring
  Boot in `tech.jhipster:jhipster-parent/<v>/jhipster-parent-<v>.pom` (`jhipster-dependencies`
  stopped at 8.x). Upgrade the framework and Boot together, to the pinned pair.
- **Config mapping.** Download the `-sources.jar` for both versions and diff:
  - the properties class (`tech/jhipster/config/JHipsterProperties.java`),
  - `META-INF/additional-spring-configuration-metadata.json`,
  - `META-INF/spring/org.springframework.boot.autoconfigure.AutoConfiguration.imports`,
  - every framework class the project imports (`grep -rhoE 'import (static )?tech\.jhipster\.[A-Za-z.]+' src | sort | uniq -c`).
- **Generator templates.** Diff `generators/spring-boot/templates/src/main/resources/config/application*.yml.ejs`
  between the two release tags (raw.githubusercontent.com). Ignore EJS-only churn; map every
  real key change onto the project's `application*.yml` (main and test).
- **Exit option.** Measure framework usage (imported classes, files, auto-configs used). If it
  is small, or the pin blocks upgrades the project needs, propose an exit: copy the used
  classes into the project package, keep the property prefixes so yml stays unchanged,
  replace needed auto-configs with plain `@Configuration`, drop the dependency, and re-enable
  Renovate for the stack. Present it as a separate follow-up plan unless the user asks otherwise.

## 5. Breaking-change research

For every major and minor jump, read the official sources for **every intermediate version**
(not only the target): release notes, migration guides, `CHANGELOG`, GitHub releases, upgrade
wiki pages. Collect:

- removed or renamed APIs, classes, annotations;
- removed or renamed configuration properties;
- default-behavior changes (these break silently);
- deprecations that the next version removes;
- new startup-time validations.

Keep the source URL for every item. For a large stack, fan out at most 3 Explore agents in
parallel, one per dependency group, each told to research *and* grep the codebase.

## 6. Impact scan

Grep code, config (`*.yml`, `*.properties`, helm values, env vars in manifests) and build
files for each flagged item. Record `file:line`. Classify:

- **Preliminary refactor** — works on the current version and is required (or safer) for
  the new one, e.g. replacing a deprecated API. Lands in its own MR first.
- **Same-MR change** — only compiles/works together with the bump.
- **No impact** — say so explicitly, so the reader knows it was checked.

Also flag **runtime-only risks** that tests will not catch: config excluded from test
profiles (`@Profile("!test…")`), startup validations, prod-only properties. Verify the key
claims from agents by reading the code yourself before putting them in the plan.

Compile with deprecation warnings on the current version (`-Xlint:deprecation`,
`tsc --noEmit`, …) when a jump removes previously deprecated APIs.

Before a config- or behavior-based finding goes into the plan, check that the setting is
actually in effect. An explicit `@Enable…` annotation or a user-defined bean often makes the
framework's auto-configuration back off, so its properties do nothing. Read the
auto-configuration's conditions in the target version's sources, and check the startup log.

## 6b. Prototype on the target version

Release notes miss things (e.g. a stricter config binder). In a throwaway worktree
(`git worktree add --detach <scratch>/wt-target <branch>`), apply only the version bumps
and start the app with a non-test profile against local services. Every startup failure
there is a preliminary refactor candidate. Fix it in the worktree, restart, and repeat until
the app starts. Record each fix for the plan, then remove the worktree.

When you stop the app, find its PID in a separate command. Your own shell's command line
contains the search pattern, so `pkill -f` or `pgrep -f` in the same command can kill that shell.

## 7. Plan — then stop

Write the plan (plan file if in plan mode, otherwise in chat):

- Inventory table (current → target, notes, blockers).
- Preliminary refactors with `file:line` and the reason.
- Ordered MR list: refactors first, each mergeable on its own; then one MR per upgrade group,
  lowest risk first. Each MR: conventional-commit title, contents, regression checks.
- Verification per MR.
- Follow-ups (framework exit, Renovate config changes, deferred majors).

**Stop and ask for approval.** Do not edit anything before it.

## 8. Execute (after approval)

- One feature branch per MR from an up-to-date default branch.
- Apply the bump and the listed changes; run the project's build, lint and tests using the
  commands from the README / CI template. Fix fallout; if fallout is large or unexpected,
  stop and report instead of improvising a refactor.
- When step 6 found runtime-only risks, start the app with a non-test profile and check
  that the context starts and the key endpoints respond.
- Rules: conventional commits; never edit `CHANGELOG.md` or bump the project version; never
  run `terraform plan/apply` locally; commit, push and open MRs only when the user asks.

## 9. Report

Per MR: versions changed, code/config changes, test and smoke-test results (with failures
shown in full), remaining risks, follow-ups.
