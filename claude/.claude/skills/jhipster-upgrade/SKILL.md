# JHipster Upgrade Skill

Upgrade a JHipster-based Spring Boot microservice to a newer JHipster version by comparing against a freshly generated reference project.

## Prerequisites

Before running this skill:
- Generate a fresh JHipster reference project with the SAME options (applicationType, auth, cache, package name) at the target version. Place it at a known path.
- The current project must be on a dedicated branch (e.g., `chore/jhipster-update`).
- Ask the user for the reference project path if not provided.

## Workflow: Copy-then-review-diff

For each JHipster infrastructure file: copy the reference version into the project, review `git diff`, then restore project-specific customizations. This ensures all upstream changes are captured while preserving overrides.

For files that are purely project-specific (business logic, custom clients, domain entities), only fix import/API changes — never copy from reference.

## Phases

### Phase 1: Discover and document divergences

1. Compare both project structures (root files, src/main, src/test, resources).
2. Look for a `divergences.json` in this skill's directory. If it exists, load it as starting point.
3. Identify all intentional differences between the current project and the reference:
   - Different database engine than reference (e.g., MSSQL vs PostgreSQL)
   - Custom embedded server choice (e.g., Undertow vs Tomcat)
   - Missing files the project intentionally doesn't use (e.g., no Jib, no Maven wrapper, no frontend plugin, no src/main/docker/)
   - Custom config classes with business-specific logic (ApplicationProperties, CacheConfiguration tuning, SecurityConfiguration routes, custom Jackson serializers)
   - Project-specific dependencies not in reference
4. Present the divergence list to the user for confirmation. Ask about any ambiguous items (e.g., "Should we switch from Undertow to Tomcat?").
5. Save confirmed divergences to `divergences.json` for future upgrades.

### Phase 2: Root config files

6. Copy these from reference, review diff, accept or merge:
   - `.editorconfig`, `checkstyle.xml`, `.lintstagedrc.cjs`, `.prettierrc`, `.prettierignore`
   - `.gitignore` — MERGE (don't overwrite; keep project-specific entries)
7. Copy safe Java infra files that have NO project overrides (accept fully):
   - `GeneratedByJHipster.java`, `package-info.java`, `ApplicationWebXml.java`
   - Config: `DateTimeFormatConfiguration`, `SpringDocConfiguration`, `CRLFLogConverter`, `AsyncConfiguration`, `Constants`
   - Security: `AuthoritiesConstants`, `SpringSecurityAuditorAware`
   - Management: `SecurityMetersService`
   - Client: `UserFeignClientInterceptor`
8. Copy Java files with minor upstream changes (e.g., `@Serial` annotation added):
   - `CoreApp.java` (or equivalent main class), error classes (`BadRequestAlertException`, `FieldErrorVM`, `ErrorConstants`)
   - `AbstractAuditingEntity.java` — if project extended it with custom fields, add `@Serial` manually instead of copying

**CHECKPOINT**: `mvn compile` should still pass.

### Phase 3: POM version bumps & dependency changes

9. Compare both `pom.xml` files thoroughly. Build a diff table with 5 categories:
   - **Unchanged** — deps in both projects, no action needed
   - **Renamed** — artifactId or groupId changed (e.g., `starter-aop` -> `starter-aspectj`, `hibernate-jpamodelgen` -> `hibernate-processor`)
   - **Added** — new in reference, needs adding
   - **Removed** — dropped in reference, evaluate and remove
   - **Kept** — project-specific deps not in reference, preserve (check divergences)
10. Present the full diff table to the user for review before applying.
11. Update parent Spring Boot version.
12. Update version properties. Remove properties now managed by the parent BOM.
13. Apply dependency changes per the diff table. Respect divergences (e.g., keep project's DB driver, skip reference's DB driver).
14. Update plugins: annotation processor paths, enforcer rules, liquibase plugin deps/config. Remove explicit versions for parent-managed plugins.
15. Update profiles (IDE, dev, prod) for renamed artifacts.

**CHECKPOINT**: Do NOT compile yet — Java code needs fixing in Phase 4.

### Phase 4: Java config migration — copy & diff

16. Copy JHipster config files from reference, then review `git diff` to restore customizations:
    - **No overrides** — accept fully: `LoggingConfiguration`, `LoggingAspectConfiguration`, `SecurityUtils`, `WebConfigurer`, `FeignConfiguration`, `DatabaseConfiguration`
    - **Has overrides** — accept ref structure, then restore custom logic:
      - `SecurityConfiguration` — restore custom security routes (check divergences)
      - `CacheConfiguration` — restore custom cache tuning and entity cache entries
      - `JacksonConfiguration` — restore custom serializers/deserializers
      - `LiquibaseConfiguration` — accept new imports/async pattern
      - `ExceptionTranslator` — review carefully, accept new patterns
    - **New files** — copy from reference (e.g., `JacksonHibernateConfiguration`, `CacheKeyGeneratorConfiguration`)
17. Fix relocated Spring Boot package imports across ALL Java files. Scan with grep and fix systematically. Common relocations between major versions:
    - `boot.autoconfigure.jdbc` -> `boot.jdbc.autoconfigure`
    - `boot.autoconfigure.liquibase` -> `boot.liquibase.autoconfigure`
    - `boot.autoconfigure.cache` -> `boot.cache.autoconfigure`
    - `boot.autoconfigure.orm.jpa` -> `boot.hibernate.autoconfigure`
    - `boot.test.autoconfigure.web.servlet` -> `boot.webmvc.test.autoconfigure`
    - `boot.web.client.RestTemplateBuilder` -> `boot.restclient.RestTemplateBuilder`
    - `boot.actuate.health` -> `boot.health.contributor`
    - (Verify actual relocations for the specific Spring Boot version being upgraded to)
18. Fix library namespace migrations if applicable (e.g., Jackson `com.fasterxml.jackson.core/databind` -> `tools.jackson`).
    IMPORTANT: Jackson annotation imports (`com.fasterxml.jackson.annotation.*`) typically do NOT change. Spring-managed ObjectMapper beans and Jackson 2.x module types (`JavaTimeModule`, `Jdk8Module`) may stay on Jackson 2.x. Only JHipster infra code and Hibernate modules may use Jackson 3.x (`tools.jackson`). Test with compilation — don't guess.
19. Merge changes into `ApplicationProperties.java` — NEVER overwrite. Add new JHipster inner classes (e.g., `Liquibase`) while keeping all project-specific fields.
20. Remove references to removed dependencies in YAML config files (e.g., logger config for removed libraries).

**CHECKPOINT**: `mvn compile` MUST pass. Fix iteratively.

### Phase 5: Test infrastructure migration

21. Copy test files from reference, review diffs:
    - Accept fully: `IntegrationTest`, `AsyncSyncConfiguration`, security tests, `TestUtil`, exception translator tests
    - Review and restore: `TechnicalStructureTest` — keep custom architecture layers if any
22. If the test container pattern changed (e.g., class-based -> interface-based with `@ImportTestcontainers`), adapt for your DB engine. Create the appropriate test container class for your database type.
23. Delete obsolete test infrastructure files (old embedded annotations, context customizer factories, `spring.factories`).
24. Copy test resources (`application-test*.yml`), review diffs, restore DB-specific settings. Note: if tests now use `@DynamicPropertySource`, hardcoded DB URLs in test YMLs may no longer be needed.

**CHECKPOINT**: `mvn verify` should pass (requires Docker for testcontainers).

### Phase 6: YAML & resource configuration

25. Copy main resources from reference, then carefully restore project overrides:
    - `application.yml` — restore: custom Spring Cloud/Feign config, multipart limits, CORS settings, custom `application:` properties, tracing/monitoring config, DB-specific settings
    - `application-dev.yml` — restore: DB URL/credentials, CORS, external service URLs, custom logging levels, cache pool sizes, JWT secrets
    - `application-prod.yml` — restore: DB URL/credentials, cache pool sizes, JWT secrets, custom application properties
    - `logback-spring.xml` — restore DB-specific loggers, add/remove server-specific loggers if server changed
    - Other resources: i18n, static, templates, banner
26. Remove config for removed dependencies. Remove config for features not used (e.g., `spring.docker.compose` if project doesn't use it).

**CHECKPOINT**: Application should start.

### Phase 7: JDK version alignment

When the upgrade involves a new Java version (e.g., Java 21 → Java 25):

33. Update `pom.xml`:
    - `<java.version>` property
    - `maven-enforcer-plugin` `requireJavaVersion` range and message
34. Update `Dockerfile`:
    - Base image tag (e.g., `eclipse-temurin:21-jre` → `eclipse-temurin:25-jre`)
    - Remove deprecated JVM flags (`-noverify` was removed in modern JDKs, `-Djava.security.egd=file:/dev/./urandom` is unnecessary since Java 11+)
    - Use exec form `ENTRYPOINT` instead of shell form `CMD` for proper signal handling
    - Remove unused `EXPOSE` ports (e.g., Hazelcast 5701 if using Redis)
35. Update `.dev/Dockerfile.build` (multi-stage) — same base image updates for both builder and runtime stages.
36. Update `.gitlab-ci.yml` (or equivalent CI config):
    - Build image (e.g., `maven:3-eclipse-temurin-21` → `maven:3-eclipse-temurin-25`)
37. Update `docker-compose.yml` if it references a JDK base image.
38. Update `helm/` templates if they embed JVM flags or JDK-specific config:
    - Remove init containers that are replaced by app-level resilience (e.g., busybox DB readiness checks → Spring Boot startup probes)
    - Clean up dead env vars referencing removed dependencies
    - Pin sidecar/init container images to specific versions (no `:latest`)
39. Update logging for production:
    - If the new Spring Boot version supports structured logging (e.g., `logging.structured.format.console=logstash`), enable JSON logging for prod profile in `logback-spring.xml` for log aggregation (Loki, ELK, etc.)

### Phase 8: Verification

40. Run `mvn clean compile` — must pass.
41. Run `mvn package -DskipTests` — must pass. If modernizer-maven-plugin fails on pre-existing code, set `<failOnViolations>false</failOnViolations>` and address violations separately.
42. Run `docker build` if the project has a Dockerfile — must pass.
43. Grep for stale imports/references — all should return empty:
    ```
    grep -r "old.relocated.package" src/ --include="*.java"
    grep -r "removed-artifact-name" pom.xml
    ```
44. Grep for stale JDK version references:
    ```
    grep -rn "temurin.*OLD_VERSION\|java\.version.*OLD_VERSION" pom.xml Dockerfile .dev/ .gitlab-ci.yml docker-compose.yml
    ```
45. Run `mvn dependency:tree` and review for version conflicts.
46. Run `mvn verify` for full test suite (requires Docker for testcontainers).

## Key Principles

- **Copy-then-diff** is safer than edit-in-place — you catch all upstream changes.
- **Never overwrite business logic** — domain entities, services, repositories, controllers, custom clients are project-specific.
- **Preserve intentional divergences** — always check `divergences.json` before applying changes.
- **Jackson 2.x vs 3.x coexistence** — Spring Boot 4.0+ ships both. Don't blindly rename all Jackson imports. Annotations stay `com.fasterxml`. Spring-managed beans may stay 2.x.
- **Test with compilation first, runtime second** — `mvn compile` catches 90% of issues.
- **Document new divergences** — if you decide to skip a reference change, add it to `divergences.json` for next time.
- **Ask before deciding** — when a divergence is ambiguous (e.g., switch embedded server?), ask the user rather than assuming.
