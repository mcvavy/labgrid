# GHA runners scale set (Labgrid)

Org-level GitHub Actions runner scale set named **labgrid** (`runs-on: labgrid`) via [gha-runner-scale-set 0.14.2](https://github.com/actions/actions-runner-controller).

| Item | Value |
| --- | --- |
| Chart path | `Apps/charts/gha-runners` |
| Argo app | `gha-runners` → namespace `gha-runners-system` |
| Controller | `Apps/charts/arc` → `arc-system` |
| Scale set name | `labgrid` |
| Capacity | `minRunners: 0`, `maxRunners: 2` |
| Auth Secret | `github-arc-app` (from ExternalSecret → AKV key **names** only) |

ApplicationSet deploys `Apps/charts/<name>` to `<name>-system`, so this chart is `gha-runners` (not `arc-runners`) to avoid a double `-system` suffix while keeping a clear runner chart name.

## Prerequisites

1. Sync `Apps/charts/arc` so ServiceAccount `arc-gha-rs-controller` exists in `arc-system`.
2. Create AKV secrets listed in [../arc/AKV-SETUP.md](../arc/AKV-SETUP.md) before ExternalSecret can become Ready.
3. External Secrets Operator + `ClusterSecretStore` `azure-kv-cluster-store` already on Labgrid.

## Public-repo secret hygiene

Allowed in git: ExternalSecret `remoteRef.key` names and `githubConfigSecret: github-arc-app` (Secret **name**).

Never commit: PEM keys, PATs, App/installation IDs as literal chart values, or Helm `github_token` / inline `github_app_private_key`.

Pre-merge check: ensure no PEM blocks or GitHub credential tokens appear under these chart paths (search for private-key armor headers and classic token prefixes).

## Dependencies

```bash
cd Apps/charts/gha-runners
DOCKER_CONFIG=/tmp/empty-docker helm dependency update
```

## Deploy

Push to `main` — ApplicationSet syncs `values-production.yaml`. After sync, confirm scale set **labgrid** under org Settings → Actions → Runners.
