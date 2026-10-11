# CloudNativePG PostgreSQL 17 + official PGDG pgvector (CREATE EXTENSION vector).
# Required for n8n Postgres PGVector Store / LangChain pgvector — not pgvecto.rs.
#
# Tag MUST start with the PostgreSQL version (CNPG auto-detects major from the tag).
# Published as: ghcr.io/mcvavy/labgrid-cnpg-pgvector:17.2
FROM ghcr.io/cloudnative-pg/postgresql:17.2

USER root
RUN set -eux; \
	apt-get update; \
	apt-get install -y --no-install-recommends postgresql-17-pgvector; \
	rm -rf /var/lib/apt/lists/* /tmp/*

# postgres UID used by cloudnative-pg/postgresql images
USER 26
