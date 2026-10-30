# Thin overlay: add POST /v3/scenario/upsert on latest stable Memory Core.
# Base: agentmemory/memory-core:1.0.3 (product v2.0.3; not latest floating).
FROM agentmemory/memory-core:1.0.3@sha256:a5ad57a47540b0a1be2cb77b0bac7c47dca38c99d2db7d20f9d512c714928280

LABEL org.opencontainers.image.title="tdai-memory-core-scenario-upsert"
LABEL org.opencontainers.image.description="Thin overlay of agentmemory/memory-core:1.0.3 adding POST /v3/scenario/upsert"
LABEL org.opencontainers.image.source="https://github.com/TencentCloud/TencentDB-Agent-Memory"
LABEL tdai.overlay.base_image="agentmemory/memory-core:1.0.3"
LABEL tdai.overlay.base_digest="sha256:a5ad57a47540b0a1be2cb77b0bac7c47dca38c99d2db7d20f9d512c714928280"
LABEL tdai.overlay.purpose="scenario-upsert"
LABEL tdai.overlay.revision="20261030"
LABEL tdai.overlay.files="src/gateway/v2-router.ts,src/gateway/v2-schemas.ts"

# Image runs TypeScript via tsx from /app/src/gateway/server.ts
COPY patched/v2-router.ts /app/src/gateway/v2-router.ts
COPY patched/v2-schemas.ts /app/src/gateway/v2-schemas.ts
