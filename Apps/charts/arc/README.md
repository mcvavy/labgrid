# ARC controller (Labgrid)

GitHub Actions Runner scale-set **controller** via [gha-runner-scale-set-controller 0.14.2](https://github.com/actions/actions-runner-controller).

| Item | Value |
| --- | --- |
| Chart path | `Apps/charts/arc` |
| Argo app | `arc` → namespace `arc-system` |
| Companion | `Apps/charts/gha-runners` (scale set + ExternalSecret) |

ApplicationSet always deploys `Apps/charts/<name>` to namespace `<name>-system`, so this chart is named `arc` (not `arc-systems`) to land in `arc-system`.

## Prerequisites

1. Complete [AKV-SETUP.md](./AKV-SETUP.md) (GitHub App values in Azure Key Vault only).
2. Sync this chart **before** or together with `gha-runners` (controller must exist for the scale set RoleBinding).
3. No secrets belong in this chart.

## Dependencies

```bash
cd Apps/charts/arc
DOCKER_CONFIG=/tmp/empty-docker helm dependency update
```

(`DOCKER_CONFIG` avoids local GPG/pass helpers timing out against GHCR.)

## Deploy

Push to `main` under `Apps/charts/arc` — ApplicationSet syncs `values-production.yaml`. Do not `kubectl`/`helm` apply from a laptop unless you are intentionally bypassing GitOps.
