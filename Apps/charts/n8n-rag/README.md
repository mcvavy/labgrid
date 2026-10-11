# n8n-rag — CNPG + pgvector for Chatwoot / n8n RAG

Dedicated PostgreSQL 17 cluster with the standard **pgvector** extension (`CREATE EXTENSION vector`) for n8n’s Postgres PGVector Store nodes. Lives in namespace `n8n-rag-system` (ApplicationSet: chart basename → `{basename}-system`).

Separate from the n8n app database (`n8n-system` / `n8n-pgcluster`) so RAG embeddings can scale and restore independently.

## Prerequisites (Azure + AKV)

Do these before (or right after) the Argo app syncs; backups stay unhealthy until the ExternalSecret resolves.

1. **Blob container** on storage account `labgrid`:

   ```text
   n8n-rag-pg-backup
   ```

   Same account as `n8n-pg-backup` / `tranzr-moves-pg-backup`.

2. **SAS token** for that container (or account-scoped with container access):
   - Permissions: Read, Write, Create, Delete, List (Barman / CNPG object store)
   - Expiry: align with your other Labgrid PG backup SAS tokens

3. **Azure Key Vault** secrets (ClusterSecretStore `azure-kv-cluster-store`):

   | AKV secret name | Used as |
   | --- | --- |
   | `labgrid-storage-account-name` | Already present — reused |
   | `n8n-rag-pg-backup-sas-token` | **Create** — SAS token value (no leading `?`) |

4. **GHCR image** (first deploy):

   - Workflow: `.github/workflows/n8n-rag-pgvector-image.yml` (`workflow_dispatch` or push of `image/**`)
   - Image: `ghcr.io/mcvavy/labgrid-cnpg-pgvector:17.2`
   - Package should be public (workflow best-effort) so the cluster needs no `imagePullSecrets`

## What Argo deploys

| Resource | Name / value |
| --- | --- |
| Namespace | `n8n-rag-system` |
| CNPG Cluster | `n8n-rag-pgcluster` |
| RW service | `n8n-rag-pgcluster-rw.n8n-rag-system.svc.cluster.local` |
| App DB / owner | `n8n_rag` / `n8nrag` |
| App credentials Secret | `n8n-rag-pgcluster-app` (`username`, `password`, `uri`, …) |
| Backup ExternalSecret → K8s Secret | `azure-credential` |
| Extension | `vector` via `postInitApplicationSQL` |

## n8n Postgres credential (for PGVector nodes)

Create a Postgres credential in n8n (or reuse via env later):

| Field | Value |
| --- | --- |
| Host | `n8n-rag-pgcluster-rw.n8n-rag-system.svc.cluster.local` |
| Port | `5432` |
| Database | `n8n_rag` |
| User / Password | from Secret `n8n-rag-pgcluster-app` in `n8n-rag-system` |
| SSL | disable (in-cluster) |

```bash
kubectl -n n8n-rag-system get secret n8n-rag-pgcluster-app \
  -o jsonpath='{.data.username}' | base64 -d; echo
kubectl -n n8n-rag-system get secret n8n-rag-pgcluster-app \
  -o jsonpath='{.data.password}' | base64 -d; echo
```

Verify extension:

```bash
kubectl -n n8n-rag-system exec -it n8n-rag-pgcluster-1 -- \
  psql -U postgres -d n8n_rag -c '\dx vector'
```

## Wire RAG workflows (after cluster is Ready)

1. Replace **Simple Vector Store** with **Postgres PGVector Store** on ingest + AgentBot RAG.
2. Same collection / table name on both (e.g. `tranzzer_policies`).
3. Keep OpenRouter embeddings credential; dimensions must match the embedding model.
4. Re-run ingest once, then restore n8n `replicaCount` > 1 if desired (store is shared).

## Local image build (optional)

```bash
cd Apps/charts/n8n-rag/image
docker build -t ghcr.io/mcvavy/labgrid-cnpg-pgvector:17.2 .
docker push ghcr.io/mcvavy/labgrid-cnpg-pgvector:17.2
```

Do **not** retag as `latest` only — CNPG requires the tag to start with the PostgreSQL version.
