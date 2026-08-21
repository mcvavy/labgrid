# Labgrid ARC runner image

Thin overlay on `ghcr.io/actions/actions-runner` for Tranzzer CI on the `labgrid` scale set.

| Tag | Registry |
| --- | --- |
| `0.1.0` / `latest` | `ghcr.io/mcvavy/labgrid-actions-runner` |

## Why

Stock runner image lacks `libatomic.so.1` (pnpm/`@pnpm/exe` fails with exit 127) and Chromium OS libs Playwright needs.

## Build / publish

Prefer the workflow [`.github/workflows/arc-runner-image.yml`](../../../../.github/workflows/arc-runner-image.yml) (`workflow_dispatch` or push under `runner-image/`).

Locally:

```bash
cd Apps/charts/gha-runners/runner-image
docker build -t ghcr.io/mcvavy/labgrid-actions-runner:0.1.0 .
docker push ghcr.io/mcvavy/labgrid-actions-runner:0.1.0
```

Ensure the GHCR package is **public** (or add `imagePullSecrets` on the scale set).

## Chart

`values-production.yaml` → `gha-runner-scale-set.template.spec.containers[0].image`.
