# Supabase (Labgrid production)

Self-hosted Supabase on the Labgrid home cluster using [supabase-community/supabase-kubernetes](https://github.com/supabase-community/supabase-kubernetes) chart `0.5.6`.

| Item | Value |
|------|-------|
| Argo app | `supabase` (ApplicationSet `labgrid-production`) |
| Namespace | `supabase-system` |
| Release name | `supabase` |
| URL | https://supabase.labgrid.net |
| SMTP from | `testing@tranzrmoves.com` (ACS `acs-smtp-*` AKV keys) |

## Dependencies

```bash
helm dependency update Apps/charts/supabase
```

## Deploy

Pushed to `main` under `Apps/charts/supabase` — Argo CD syncs automatically with `values-production.yaml`.

Manual install (debug):

```bash
helm upgrade --install supabase Apps/charts/supabase \
  -n supabase-system --create-namespace \
  -f Apps/charts/supabase/values-production.yaml
```

## Architecture

Kong ingress at `supabase.labgrid.net` routes API paths and Studio (`/` with basic-auth). Bundled Postgres, MinIO (S3 storage), GoTrue, PostgREST, Realtime, Storage, Analytics. Vector disabled (no hostPath log scraping).

## Azure Key Vault secrets

All credentials sync via External Secrets (`azure-kv-cluster-store`).

**Reuse existing:** `acs-smtp-username`, `acs-smtp-password` (shared with Chatwoot; synced into `supabase-smtp`).

**Generate JWT trio together** — use [Supabase `generate-keys.sh`](https://github.com/supabase/supabase/blob/master/docker/utils/generate-keys.sh):

```bash
curl -fsSL https://raw.githubusercontent.com/supabase/supabase/master/docker/utils/generate-keys.sh | sh
```

Map `JWT_SECRET` → `labgrid-supabase-jwt-secret`, `ANON_KEY` → `labgrid-supabase-jwt-anon-key`, `SERVICE_ROLE_KEY` → `labgrid-supabase-jwt-service-key`.

| AKV key | K8s secret | Key | Generate |
|---------|------------|-----|----------|
| `acs-smtp-username` | `supabase-smtp` | `username` | existing (Chatwoot) |
| `acs-smtp-password` | `supabase-smtp` | `password` | existing (Chatwoot) |
| `labgrid-supabase-jwt-secret` | `supabase-jwt` | `secret` | `generate-keys.sh` → `JWT_SECRET` |
| `labgrid-supabase-jwt-anon-key` | `supabase-jwt` | `anonKey` | `generate-keys.sh` → `ANON_KEY` |
| `labgrid-supabase-jwt-service-key` | `supabase-jwt` | `serviceKey` | `generate-keys.sh` → `SERVICE_ROLE_KEY` |
| `labgrid-supabase-db-password` | `supabase-db` | `password` | `generate-keys.sh` → `POSTGRES_PASSWORD` |
| `labgrid-supabase-dashboard-username` | `supabase-dashboard` | `username` | e.g. `supabase` |
| `labgrid-supabase-dashboard-password` | `supabase-dashboard` | `password` | `generate-keys.sh` → `DASHBOARD_PASSWORD` |
| `labgrid-supabase-analytics-public-token` | `supabase-analytics` | `publicAccessToken` | `generate-keys.sh` → `LOGFLARE_PUBLIC_ACCESS_TOKEN` |
| `labgrid-supabase-analytics-private-token` | `supabase-analytics` | `privateAccessToken` | `generate-keys.sh` → `LOGFLARE_PRIVATE_ACCESS_TOKEN` |
| `labgrid-supabase-realtime-secret-key-base` | `supabase-realtime` | `secretKeyBase` | `generate-keys.sh` → `SECRET_KEY_BASE` |
| `labgrid-supabase-meta-crypto-key` | `supabase-meta` | `cryptoKey` | `generate-keys.sh` → `PG_META_CRYPTO_KEY` |
| `labgrid-supabase-minio-user` | `supabase-minio` | `user` | choose a MinIO root user |
| `labgrid-supabase-minio-password` | `supabase-minio` | `password` | `generate-keys.sh` → `MINIO_ROOT_PASSWORD` |
| `labgrid-supabase-s3-key-id` | `supabase-s3` | `keyId` | same as minio user |
| `labgrid-supabase-s3-access-key` | `supabase-s3` | `accessKey` | same as minio password |
| `labgrid-supabase-minio-password` | `supabase-s3` | `password` | same value again — upstream chart reads MinIO root password from the s3 secret when `secret.s3.secretRef` is set |

Verify sync after deploy:

```bash
kubectl get externalsecret -n supabase-system
```

All 16 AKV keys in the table above must exist before pods become healthy. Common failures:

- `supabase-dashboard` → `SecretSyncedError` — create `labgrid-supabase-dashboard-username` and `labgrid-supabase-dashboard-password` (blocks Kong and Studio).
- MinIO / storage `CreateContainerConfigError` on `supabase-s3` key `password` — ensure the chart includes the s3 `password` mapping (from `labgrid-supabase-minio-password`).
- MinIO `CrashLoopBackOff` with `file access denied` on `/data` — Chainguard MinIO runs as UID 65532; set `deployment.minio.podSecurityContext.fsGroup: 65532` (included in `values.yaml`) so Synology PVCs are group-writable.

## Tranzr app integration

After Supabase is healthy, update tranzr-gitops AKV keys (`supabase-url`, `supabase-key`, `tranzr-supabase-database-connection-string`) to point at this instance — separate follow-up.
