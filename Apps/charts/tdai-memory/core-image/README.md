# Memory Core overlay: `POST /v3/scenario/upsert`

Thin overlay of the latest **stable** Memory Core image so authenticated clients can **create** L2 scenario files over HTTPS. Official Core `POST /v3/scenario/write` remains update-only (404 if the path is missing).

## Base

| Field | Value |
|-------|--------|
| Image | `agentmemory/memory-core:1.0.3` (product v2.0.3) |
| amd64 digest | `sha256:a5ad57a47540b0a1be2cb77b0bac7c47dca38c99d2db7d20f9d512c714928280` |
| index digest | `sha256:342331d5ccdb31ce84ac1ba205aa0b1a8b16a13fe71b6a104d17d41197eb7112` |

Gateway sources match GitHub tag `v2.0.3`. Not used as base: floating `latest`, or older `1.0.1` / `1.0.2`.

## Changed files

| Path in image | Role |
|---------------|------|
| `/app/src/gateway/v2-schemas.ts` | `scenarioUpsertRequestSchema` (`.md` only, content ≤ 1 MiB, summary ≤ 2000) |
| `/app/src/gateway/v2-router.ts` | `POST /v3/scenario/upsert` only; write unchanged |

`upstream/` is a byte copy from the base image for review. `patched/` is the minimal delta.

## Semantics

- Create if missing (`operation=created`); update if present (`operation=updated`).
- Preserve META `created` on update; refresh `updated`; set/replace `summary` when provided.
- Same post-steps as write: `syncProfileToVdb`, `refreshSceneIndex`, `recordAudit` (action `update`).
- **Last-writer-wins** (storage has no exclusive create / CAS).
- PVC layout unchanged.

## Local build

Chart defaults use stock Docker Hub `agentmemory/memory-core:1.0.3`. Labgrid Argo uses the public GHCR overlay (see chart README + `values-overlay-upsert.yaml`).

```bash
cd Apps/charts/tdai-memory/core-image
docker build --platform linux/amd64 \
  -t tdai-memory-core:scenario-upsert-overlay-20261030 \
  .
# Prefer: GitHub Actions workflow "TDAI Memory Core overlay image"
```

Publish name:  
`ghcr.io/mcvavy/labgrid-tdai-memory-core:scenario-upsert-20261030`

## Rollback

Pin Core back to `ghcr.io/mcvavy/labgrid-tdai-memory-core:scenario-upsert-20260915` or stock `agentmemory/memory-core:1.0.1`. Existing PVC data stays valid for the same storage layout.
