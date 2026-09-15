# Thin overlay: add POST /v3/scenario/upsert on latest stable Memory Core.
# Base: agentmemory/memory-core:1.0.1 (not 1.0.2-beta.1 / latest).
FROM agentmemory/memory-core:1.0.1@sha256:9798254a8cc06276b7c5b3c19df49f136fae25d579564e1f01f9c4b9b8cd2d11

LABEL org.opencontainers.image.title="tdai-memory-core-scenario-upsert"
LABEL org.opencontainers.image.description="Thin overlay of agentmemory/memory-core:1.0.1 adding POST /v3/scenario/upsert"
LABEL org.opencontainers.image.source="https://github.com/TencentCloud/TencentDB-Agent-Memory"
LABEL tdai.overlay.base_image="agentmemory/memory-core:1.0.1"
LABEL tdai.overlay.base_digest="sha256:9798254a8cc06276b7c5b3c19df49f136fae25d579564e1f01f9c4b9b8cd2d11"
LABEL tdai.overlay.purpose="scenario-upsert"
LABEL tdai.overlay.revision="20260915"
LABEL tdai.overlay.files="src/gateway/v2-router.ts,src/gateway/v2-schemas.ts"

# Image runs TypeScript via tsx from /app/src/gateway/server.ts
COPY patched/v2-router.ts /app/src/gateway/v2-router.ts
COPY patched/v2-schemas.ts /app/src/gateway/v2-schemas.ts
