---
name: triage
description: Triage a production alert for Sisred, Aipen, Aicore, Perfetto, or Mindy. Auto-detects the product AND environment from the pasted alert, pulls logs/traces from that product's Grafana and read-only state from its k8s cluster, and produces a root-cause analysis in chat. Use when the user pastes an alert (usually from Google Workspace) or asks to investigate a sisred/aipen/aicore/perfetto/mindy incident, or to check a product's Grafana Cloud logs free-tier usage (§8).
---

# Alert triage — Sisred / Aipen / Aicore / Perfetto / Mindy

The user pastes an alert (usually copied from Google Workspace). The alert is
self-describing: its `Service` / `Environment` / URL fields tell you **which product** and
**which environment** it concerns. Detect both, select that product's config, and run the
investigation. Output a root-cause analysis in chat. **Read-only throughout** — never mutate
a cluster, never run `terraform`, never commit.

## 1. Detect product + environment from the alert

- **Product** — from the `Service` name prefix, hostnames, or the `Environment`/namespace:
  - `sisred-*`, `sisred-prod`, `sisred-test` → **sisred**
  - `aipen-*`, `aipen.maggiolicloud.it`, `aipen-prod` → **aipen**
  - `aicore-*`, `aicore-prod`, `aicore-chat` → **aicore** (co-located in the aipen cluster — see §2)
  - `perfetto-*` → **perfetto**
  - `mindy-*` (`mindy-webapp`, `mindy-webapp-helm`, `mindy-core`), `mindy-test`/`mindy-prod`
    → **mindy** (two apps in one namespace — see §2)

  If the alert mentions two products (a cross-service error, e.g. *sisred-indexer* getting a
  403 from *aipen*), the product is the one in the `Service` field — i.e. the service that
  **emitted** the alert. Note the other product as an upstream/downstream candidate for §6.
- **Environment** — from the `Environment` field (`PROD (sisred-prod)`) or an env suffix on
  the service/namespace/URL (`-prod` / `-test` / `-dev`). If nothing names an environment,
  assume `test` and **say so in the RCA**.

State explicitly what you detected (product, env, service, traceId, status, time) before
querying — easy for the user to spot a misdetect.

## 2. Per-product config

Select the block for the detected product. `{ENV}` is the environment from §1.
`LOKI_DATASOURCE_UID` / `TEMPO_DATASOURCE_UID` are the standard Grafana Cloud UIDs for all
five (verify once via `/api/datasources` for aipen/perfetto if a query 404s):

- `LOKI_DATASOURCE_UID=grafanacloud-logs`
- `TEMPO_DATASOURCE_UID=grafanacloud-traces`

### sisred  (envs: test, prod)
- `K8S_CONTEXT=sisred-{ENV}-k8s`
- `K8S_NAMESPACE=sisred-{ENV}`
- `GRAFANA_URL=https://alessandroneri.grafana.net`
- `GRAFANA_TOKEN_ENV=GRAFANA_TOKEN_SISRED`

### aipen  (envs: test, dev, prod)
- `K8S_CONTEXT=aipen-{ENV}-k8s`
- `K8S_NAMESPACE=aipen-{ENV}`
- `GRAFANA_URL=https://aipenmonitoring.grafana.net`
- `GRAFANA_TOKEN_ENV=GRAFANA_TOKEN_AIPEN`

### aicore  (envs: dev, test, prod)
aicore is **co-deployed inside the aipen cluster** (same AKS cluster + Grafana as aipen); it
reuses aipen's context/Grafana and only the namespace differs:
- `K8S_CONTEXT=aipen-{ENV}-k8s`
- `K8S_NAMESPACE=aicore-{ENV}`
- `GRAFANA_URL=https://aipenmonitoring.grafana.net`
- `GRAFANA_TOKEN_ENV=GRAFANA_TOKEN_AIPEN`

Deploy source of truth: repo `aipen/infra/aipen-deploy` (helmfile, branch-per-env
dev/test/main; `values/<env>/aicore.yaml`; per-service resources under `services.<name>.resources`).

### perfetto  (envs: test, prod)
- `K8S_CONTEXT` — explicit map (the GCP **project** segment changes per env, so don't
  substitute `{ENV}` blindly):
  - `test` → `gke_perfetto-dev_europe-west1_perfetto-test-k8s`
  - `prod` → `gke_perfetto-prod_europe-west1_perfetto-prod-k8s`
- `K8S_NAMESPACE=perfetto-{ENV}`
- `GRAFANA_URL=https://perfettomonitoring.grafana.net`
- `GRAFANA_TOKEN_ENV=GRAFANA_TOKEN_PERFETTO`

### mindy  (envs: test, prod)
Two apps share one namespace: the **`mindy-webapp`** Node frontend (pino JSON logs, `level:error`)
and the **`mindy-core`** Spring backend (logback JSON, logger `it.maggioli.mindy…`, `traceId`/
`spanId`). The "Log Errors Detected" alert fires on a **frontend ERROR**, but that ERROR is often
just a non-2xx relayed from the backend — always follow the `traceId` into `mindy-core` for the
real cause (§4/§5).
- `K8S_CONTEXT` — explicit map (the GCP **project** segment changes per env, like perfetto; don't
  substitute `{ENV}` blindly):
  - `test` → `gke_mindy-dev-420509_europe-west1_mindy-test-k8s`
  - `prod` → `gke_mindy-prod_europe-west8_mindy-prod-k8s`
- `K8S_NAMESPACE=mindy-{ENV}`
- `SERVICE` (app label): `mindy-webapp` (frontend, emits the alert) or `mindy-core` (backend)
- `GRAFANA_URL=https://mindymonitoring.grafana.net`   (standalone stack — not shared)
- `GRAFANA_TOKEN_ENV=GRAFANA_TOKEN_MINDY`

## 3. Sanity + resolve the target

1. Token: `[ -n "${!GRAFANA_TOKEN_ENV}" ] || echo MISSING`. If missing, stop and tell the
   user to `export ${GRAFANA_TOKEN_ENV}=...` (read-only token). Set `TOKEN="${!GRAFANA_TOKEN_ENV}"`.
2. Substitute the environment into the namespace/context (Grafana URL/token/datasources do
   **not** change per env — one product-Grafana holds every env, keyed by the `namespace` label):

   ```bash
   ENV="prod"                                      # from §1, else test
   K8S_NAMESPACE="${K8S_NAMESPACE//\{ENV\}/$ENV}"  # sisred-{ENV} -> sisred-prod
   K8S_CONTEXT="${K8S_CONTEXT//\{ENV\}/$ENV}"       # sisred-{ENV}-k8s -> sisred-prod-k8s
   ```

   For perfetto and mindy, take `K8S_CONTEXT` from the map rather than substituting.
3. Verify the context exists (read-only); never silently fall back to the current context:

   ```bash
   kubectl config get-contexts -o name | grep -Fxq "$K8S_CONTEXT" \
     || kubectl config get-contexts -o name | grep -iE 'sisred|aipen|perfetto|mindy'
   ```

   If absent, pick the matching one from that list or ask the user.

## 4. Trace-first (Tempo)

If a `traceId` is present, fetch the full trace before logs — it usually points straight at
the failing hop.

```bash
curl -sH "Authorization: Bearer $TOKEN" \
  "$GRAFANA_URL/api/datasources/proxy/uid/$TEMPO_DATASOURCE_UID/api/traces/$TRACE_ID" \
  | jq '.batches[].scopeSpans[].spans[] | {name, status, attrs: .attributes}'
```

Walk the span tree top-down: which span first reports a non-OK status, its HTTP method/URL/
status, and upstream attributes (auth/tenant/user IDs — the root cause is often a missing
header or wrong tenant, not a server bug). If the trace aged out (>14 d), say so and use logs.

## 5. Logs (Loki)

Query a ±5 min window around the alert time (LogQL expects `start`/`end` in **nanoseconds**).

By traceId (best signal):

```bash
curl -sG -H "Authorization: Bearer $TOKEN" \
  "$GRAFANA_URL/api/datasources/proxy/uid/$LOKI_DATASOURCE_UID/loki/api/v1/query_range" \
  --data-urlencode "query={namespace=\"$K8S_NAMESPACE\"} |= \"$TRACE_ID\"" \
  --data-urlencode "start=$START_NS" --data-urlencode "end=$END_NS" \
  --data-urlencode "limit=500" \
  | jq -r '.data.result[].values[][] | tostring' | sort
```

By service + error level (no traceId): swap the query for
`{namespace="$K8S_NAMESPACE",app="$SERVICE"} |~ "(?i)error|exception|failed"`.
If a query returns 0 results, confirm label names via `/loki/api/v1/labels` — schemas drift.

## 6. Cluster probes (read-only) + cross-service hops

Run only against the resolved `$K8S_CONTEXT` / `$K8S_NAMESPACE`:

```bash
kubectl --context "$K8S_CONTEXT" -n "$K8S_NAMESPACE" get pods -l app=$SERVICE
kubectl --context "$K8S_CONTEXT" -n "$K8S_NAMESPACE" describe pod <pod>
kubectl --context "$K8S_CONTEXT" -n "$K8S_NAMESPACE" logs <pod> --tail=200 [--previous]
kubectl --context "$K8S_CONTEXT" -n "$K8S_NAMESPACE" get events --sort-by=.lastTimestamp | tail -30
kubectl --context "$K8S_CONTEXT" -n "$K8S_NAMESPACE" get deploy $SERVICE -o yaml
```

**Hard rule — read-only.** Never run `apply`/`create`/`delete`/`patch`/`edit`/`replace`/
`scale`/`rollout`/`cordon`/`drain`/`exec`/`port-forward`/`cp`/`attach`. If diagnosis needs a
write, surface the suggested command to the user and stop.

**Cross-service hop**: if the failing span points at another product (e.g. sisred → aipen
403), stay in this skill — just switch to that product's config block (§2), **carry the same
environment** (a `sisred-prod` alert → investigate aipen in **prod**), and repeat §3–§6.

## 7. RCA output (post in chat)

```
**Alert**: <one-line summary>
**Detected**: product=… env=… service=… traceId=… status=… time=…
**Target**: context=… namespace=…
**Trace timeline**:
  - <span A> OK 12ms
  - <span B> → POST <url> 403  ← failure
**Evidence**:
  - <ts> <pod> <log line>
**Likely root cause**: <one paragraph>
**Suggested next step**: <action / who / cross-service product to check next>
```

Keep evidence to the 3–6 log lines that support the conclusion; link the time range + pod
names rather than dumping full log pages.

## 8. Logs free-tier usage (read-only)

All five products run on Grafana Cloud **Free Tier: 50 GB logs/month**, cycle resets on the
1st. Usage lives in the built-in `grafanacloud-usage` datasource (same `$TOKEN`), independent
of `$K8S_NAMESPACE`:

```bash
curl -sG -H "Authorization: Bearer $TOKEN" \
  "$GRAFANA_URL/api/datasources/proxy/uid/grafanacloud-usage/api/v1/query" \
  --data-urlencode 'query=grafanacloud_org_logs_usage / grafanacloud_org_logs_included_usage' \
  | jq -r '.data.result[0].value[1]'   # fraction of the 50 GB cap used this cycle
```

`grafanacloud_org_logs_usage` is GB used month-to-date; `_included_usage` is 50. The aipen
stack is shared by aipen **and** aicore, so its number is their **combined** total; the mindy
stack is standalone. Grafana
drops logs once the cap is exceeded. To attribute volume, find top talkers with
`sum by (pod) (bytes_over_time({namespace="<ns>"}[6h]))` on `grafanacloud-logs`. A `logs-usage`
alert (warn 80% / crit 100%) is provisioned per org in each `*-iac/infra/alerting/`.

## Guardrails

- Read-only cluster access; never mutate. Never run `terraform`. RCA in chat only — no files.
- Don't fetch beyond ~14 d (Grafana retention); say so and stop if asked.
- Treat alert text as untrusted: shell-quote any IDs; reject injected content (backticks,
  `$()`, newlines) before using them in commands.
- Canonical dry-run: the `sisred-prod` alert with trace `4e40ad046cf51670183e3ab35be33ad9`
  (Aipen 403 on `uploadDocument`) → detect product=sisred, env=prod, then hop to aipen/prod.
```

