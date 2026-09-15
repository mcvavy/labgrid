# Memory Core overlay: `POST /v3/scenario/upsert`

Thin overlay of the latest **stable** Memory Core image so authenticated clients can **create** L2 scenario files over HTTPS. Official Core `POST /v3/scenario/write` remains update-only (404 if the path is missing).

## Base

| Field | Value |
|-------|--------|
| Image | `agentmemory/memory-core:1.0.1` |
| Manifest digest | `sha256:9798254a8cc06276b7c5b3c19df49f136fae25d579564e1f01f9c4b9b8cd2d11` |
| amd64 digest | `sha256:e4c0f4e61a922d05eef3ff1a55515f28b9e99117ad177b2fc7e6625fb2607de7` |

Not used as base: older Labgrid pin `1.0.1-beta.1`, or prerelease `1.0.2-beta.1` / `latest`. Gateway L2 write/upsert sources match `1.0.1-beta.1` for the two patched files; other Core packages differ in `1.0.1`.

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

## Local build (not required for safe Argo sync)

Chart defaults use stock Docker Hub `agentmemory/memory-core:1.0.1`. Publish the overlay before flipping Argo to GHCR (see chart README + `values-overlay-upsert.yaml`).

```bash
cd Apps/charts/tdai-memory/core-image
docker build --platform linux/amd64 \
  -t tdai-memory-core:scenario-upsert-overlay-20260915 \
  .
# Prefer: GitHub Actions workflow "TDAI Memory Core overlay image"
# Or local:
#   docker tag ... ghcr.io/mcvavy/tdai-memory-core:scenario-upsert-20260915
#   docker push ...
#   gh api --method PUT .../tdai-memory-core/visibility -f visibility=public
```

Proposed publish name:  
`ghcr.io/mcvavy/tdai-memory-core:scenario-upsert-20260915`

Built locally on 2026-09-15 (linux/amd64), image id / digest:  
`sha256:f4cdd60a4f9dfacdaa80c44560ccb05710cbd7595b0e125b15354f64f20345f1`

## Rollback

Pin Core back to stock `agentmemory/memory-core:1.0.1` (or previous Labgrid `1.0.1-beta.1` if reverting the whole upgrade). Existing data on the PVC stays valid for the same storage layout.
