# tdai-memory (Labgrid)

TencentDB Agent Memory on Labgrid: **Memory Core** (Gateway / MCP) + **Memory Hub** (Panel + Knowledge), with DeepSeek for Hub LLM.

ArgoCD ApplicationSet discovers `Apps/charts/tdai-memory` → app `tdai-memory`, namespace `tdai-memory-system`.

## Hostnames

| Host | Backend | Port |
|------|---------|------|
| `memory.labgrid.net` | Memory Core | 8420 |
| `memory-hub.labgrid.net` | Hub Panel | 8125 |
| `memory-ks.labgrid.net` | Hub Knowledge | 8424 |

TLS uses Gateway wildcard `labgrid-wildcard-tls` (no per-app cert). Parent Gateway: `labgrid-gateway` in `nginx-gateway`, sections `http` + `https`.

## DNS / edge

Point DNS A/CNAME for `memory`, `memory-hub`, and `memory-ks` at Gateway VIP **`192.168.1.205`**, or NPM-forward to `http://192.168.1.205:80` (Force SSL off / Cloudflare Full — same pattern as Forgejo).

## Azure Key Vault (before first sync)

Create these secrets in the vault backed by `ClusterSecretStore` `azure-kv-cluster-store`. Chart values store **key names only**.

| AKV secret name | Used as |
|-----------------|---------|
| `tdai-gateway-api-key` | Core `TDAI_GATEWAY_API_KEY` + Hub `REMOTE_INSTANCE_KEY` (Bearer for MCP) |
| `tdai-deepseek-api-key` | Hub (and Core) `LLM_API_KEY` |
| `tdai-deepseek-base-url` | optional; default `https://api.deepseek.com/v1` from values |
| `tdai-deepseek-model` | optional; default `deepseek-v4-flash` from values |
| `tdai-memory-backup-sas-token` | SAS for Blob container `tdai-memory-backup` (backup CronJob) |

Generate a strong random gateway API key (do **not** use empty/`local` — Core is publicly reachable).

Example (Azure CLI):

```bash
az keyvault secret set --vault-name labgrid --name tdai-gateway-api-key --value "$(openssl rand -hex 32)"
az keyvault secret set --vault-name labgrid --name tdai-deepseek-api-key --value "<deepseek-api-key>"

# Blob container + SAS (same storage account pattern as Forgejo/linkding PG backups)
az storage container create --account-name labgrid --name tdai-memory-backup --auth-mode login
# Create a container SAS (read/write/list/delete), then:
az keyvault secret set --vault-name labgrid --name tdai-memory-backup-sas-token --value "<sas-token-without-leading-?>"
```

## Architecture notes

- Core: **1 replica**, RWO PVC (`synology-iscsi-delete`). SQLite standalone — do not scale replicas.
- Hub: separate knowledge PVC; talks to Core via in-cluster DNS `http://tdai-memory-core:8420`.
- `KNOWLEDGE_PUBLIC_BASE_URL=https://memory-ks.labgrid.net/v3` (required).
- No Memory Proxy in this chart; agents use MCP → Core HTTPS.

## Data migration (local → cluster)

Host install was Core-only under `~/agent-memory`.

1. Stop local Core: `docker rm -f tdai-memory-core`
2. Archive: `tar -C ~/agent-memory -czf /tmp/tdai-memory-data.tgz data`
3. After PVC `tdai-memory-core-data` is Bound and Core has been synced once, run:

```bash
chmod +x Apps/charts/tdai-memory/scripts/migrate-data.sh
ARCHIVE=/tmp/tdai-memory-data.tgz ./Apps/charts/tdai-memory/scripts/migrate-data.sh
```

4. Keep FTS / `promptMode: code` from the chart ConfigMap (already in-tree).

Manual one-shot (equivalent):

```bash
kubectl -n tdai-memory-system scale deploy/tdai-memory-core --replicas=0
kubectl -n tdai-memory-system run tdai-migrate --rm -it --restart=Never \
  --overrides='{"spec":{"containers":[{"name":"migrate","image":"busybox:1.36","command":["sleep","3600"],"volumeMounts":[{"name":"data","mountPath":"/data"}]}],"volumes":[{"name":"data","persistentVolumeClaim":{"claimName":"tdai-memory-core-data"}}]}}'
# From another terminal:
kubectl -n tdai-memory-system cp /tmp/tdai-memory-data.tgz tdai-migrate:/tmp/
kubectl -n tdai-memory-system exec -it tdai-migrate -- sh -c 'cd /data && tar xzf /tmp/tdai-memory-data.tgz && ls -la'
# If archive root is "data/", move contents to /data/tdai-memory as needed
kubectl -n tdai-memory-system delete pod tdai-migrate --force --grace-period=0 2>/dev/null || true
kubectl -n tdai-memory-system scale deploy/tdai-memory-core --replicas=1
```

## MCP cutover (Cursor / Codex)

Point clients at the cluster Core (keep team/agent/user IDs from `~/agent-memory/.env`):

```bash
export TDAI_GATEWAY_URL=https://memory.labgrid.net
export TDAI_GATEWAY_BEARER=<same value as AKV tdai-gateway-api-key>
# keep TDAI_TEAM_ID / TDAI_AGENT_ID / TDAI_USER_ID
```

Reload Cursor MCP / Codex. Smoke: `tdai_recall`, then write a small atom from a second machine.

Avoid dual-writers: leave local Core stopped (or offline-only fallback).

## Smoke after Argo sync

```bash
kubectl -n tdai-memory-system get pods,svc,httproute,externalsecret,pvc
curl -fsS -H "Authorization: Bearer $TDAI_GATEWAY_BEARER" https://memory.labgrid.net/health
curl -fsS https://memory-hub.labgrid.net/health
curl -fsS https://memory-ks.labgrid.net/health
```

## Backup (PVC → Azure Blob)

Daily CronJob (03:00 UTC by default) scales Core/Hub to **0**, tars both PVCs, uploads to Azure Blob, prunes old blobs, then scales back to **1**. Brief MCP outage during the job is expected (SQLite consistency).

| Item | Value |
|------|-------|
| CronJob | `tdai-memory-backup` |
| Container | `labgrid` / `tdai-memory-backup` |
| Blobs | `core/tdai-core-<ts>.tgz`, `hub/tdai-hub-<ts>.tgz` |
| AKV | `tdai-memory-backup-sas-token` |
| Toggle | `backup.enabled` in values (`true` in `values-production.yaml`) |

### Review rendered manifests

```bash
cd Apps/charts/tdai-memory
helm template tdai-memory . -f values.yaml -f values-production.yaml -n tdai-memory-system \
  --show-only templates/backup-rbac.yaml \
  --show-only templates/backup-external-secret.yaml \
  --show-only templates/backup-configmap.yaml \
  --show-only templates/backup-cronjob.yaml
```

Or write a reviewable dump:

```bash
./scripts/render-backup-manifests.sh > /tmp/tdai-backup-manifests.yaml
```

### Manual trigger

```bash
kubectl -n tdai-memory-system create job --from=cronjob/tdai-memory-backup tdai-backup-manual-$(date +%s)
kubectl -n tdai-memory-system logs -f job/tdai-backup-manual-... -c backup
```

### Restore (DR / new cluster)

1. Sync chart + recreate AKV secrets (gateway key, DeepSeek, backup SAS).
2. Download and unpack into PVCs:

```bash
export SAS_TOKEN='<same as AKV tdai-memory-backup-sas-token>'
./Apps/charts/tdai-memory/scripts/restore-from-blob.sh list
./Apps/charts/tdai-memory/scripts/restore-from-blob.sh restore-latest
# or: CORE_TS=... HUB_TS=... ./scripts/restore-from-blob.sh restore
```

3. Smoke health + MCP bearer / team-agent IDs from `~/agent-memory/.env`.

## Out of scope

- Memory Proxy (`:8096`)
- Multi-replica / Redis Core service mode
- Staging ApplicationSet
- Velero / K8up (cluster-wide backup platform)
