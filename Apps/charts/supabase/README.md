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

**Asymmetric JWT (JWKS)** — after `labgrid-supabase-jwt-secret` is in AKV, use the official Supabase utility ([docs](https://supabase.com/docs/guides/self-hosting/self-hosted-auth-keys), [script](https://github.com/supabase/supabase/blob/master/docker/utils/add-new-auth-keys.sh)):

```bash
mkdir -p /tmp/supabase-keys && cd /tmp/supabase-keys
echo "JWT_SECRET=<paste labgrid-supabase-jwt-secret value>" > .env
touch docker-compose.yml   # stub only — script checks it exists for --update-env
curl -fsSL https://raw.githubusercontent.com/supabase/supabase/master/docker/utils/add-new-auth-keys.sh -o add-new-auth-keys.sh
sh add-new-auth-keys.sh --update-env
```

The script **prints only four values** to the terminal (`SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SECRET_KEY`, `JWT_KEYS`, `JWT_JWKS`). That is expected upstream behaviour. Two more values (`ANON_KEY_ASYMMETRIC`, `SERVICE_ROLE_KEY_ASYMMETRIC`) are written to `.env` by `--update-env` but not echoed — read them from there:

```bash
grep -E '^(SUPABASE_|ANON_|SERVICE_|JWT_)' .env
```

Copy each value into Key Vault manually (`labgrid` vault):

| `.env` variable | AKV secret name |
|---------------|-----------------|
| `SUPABASE_PUBLISHABLE_KEY` | `labgrid-supabase-publishable-key` |
| `SUPABASE_SECRET_KEY` | `labgrid-supabase-api-secret-key` |
| `ANON_KEY_ASYMMETRIC` | `labgrid-supabase-anon-key-asymmetric` |
| `SERVICE_ROLE_KEY_ASYMMETRIC` | `labgrid-supabase-service-role-key-asymmetric` |
| `JWT_KEYS` | `labgrid-supabase-jwt-keys` |
| `JWT_JWKS` | `labgrid-supabase-jwt-jwks` |

**Do not swap `JWT_KEYS` and `JWT_JWKS`** — they look similar but differ:

| Variable | Must start with | Contains | Used by |
|----------|-----------------|----------|---------|
| `JWT_KEYS` | `[` (JSON **array**) | EC private key with `"d"` and `"key_ops":["sign","verify"]` | Auth `GOTRUE_JWT_KEYS` |
| `JWT_JWKS` | `{"keys":` (JSON **object**) | EC public key only (`"verify"`) + HS256 `oct` key | PostgREST / Realtime / Storage |

Pasting `JWT_JWKS` into `labgrid-supabase-jwt-keys` causes auth `CrashLoopBackOff`:

`json: cannot unmarshal object into Go value of type []json.RawMessage`

Ignore the docker-compose “uncomment manually” warning. After deploy, JWKS at `https://supabase.labgrid.net/auth/v1/.well-known/jwks.json` should list the EC public key plus the legacy HS256 key.

| AKV key | K8s secret | Key | Generate |
|---------|------------|-----|----------|
| `acs-smtp-username` | `supabase-smtp` | `username` | existing (Chatwoot) |
| `acs-smtp-password` | `supabase-smtp` | `password` | existing (Chatwoot) |
| `labgrid-supabase-jwt-secret` | `supabase-jwt` | `secret` | [`generate-keys.sh`](https://github.com/supabase/supabase/blob/master/docker/utils/generate-keys.sh) → `JWT_SECRET` |
| `labgrid-supabase-jwt-anon-key` | `supabase-jwt` | `anonKey` | `generate-keys.sh` → `ANON_KEY` |
| `labgrid-supabase-jwt-service-key` | `supabase-jwt` | `serviceKey` | `generate-keys.sh` → `SERVICE_ROLE_KEY` |
| `labgrid-supabase-publishable-key` | `supabase-apikey` | `publishableKey` | [`add-new-auth-keys.sh`](https://github.com/supabase/supabase/blob/master/docker/utils/add-new-auth-keys.sh) |
| `labgrid-supabase-api-secret-key` | `supabase-apikey` | `secretKey` | `add-new-auth-keys.sh` |
| `labgrid-supabase-anon-key-asymmetric` | `supabase-apikey` | `anonKeyAsymmetric` | `add-new-auth-keys.sh` |
| `labgrid-supabase-service-role-key-asymmetric` | `supabase-apikey` | `serviceRoleKeyAsymmetric` | `add-new-auth-keys.sh` |
| `labgrid-supabase-jwt-keys` | `supabase-apikey` | `jwtKeys` | `add-new-auth-keys.sh` |
| `labgrid-supabase-jwt-jwks` | `supabase-apikey` | `jwtJwks` | `add-new-auth-keys.sh` |
| `labgrid-supabase-db-password` | `supabase-db` | `password` | `generate-keys.sh` → `POSTGRES_PASSWORD` |
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

All 21 AKV keys in the table above must exist before pods become healthy. Common failures:

- `supabase-dashboard` → `SecretSyncedError` — create `labgrid-supabase-dashboard-password` in AKV (username is `externalSecrets.dashboard.username` in values).
- `supabase-apikey` → `SecretSyncedError` — run official [`add-new-auth-keys.sh`](https://github.com/supabase/supabase/blob/master/docker/utils/add-new-auth-keys.sh) and create the six `labgrid-supabase-*` AKV entries above.
- Auth `CrashLoopBackOff` / `cannot unmarshal object` on `GOTRUE_JWT_KEYS` — `labgrid-supabase-jwt-keys` has `JWT_JWKS` pasted by mistake; it must be the `JWT_KEYS` line starting with `[`.
- JWKS returns `{"keys":[]}` — `GOTRUE_JWT_KEYS` not configured; deploy `supabase-apikey` secret and restart auth.
- Well-known `401` / `404` — use the full path below (not Studio root). Kong exposes JWKS and OIDC discovery without an API key only under `/auth/v1/`:

| URL | Expected |
|-----|----------|
| `https://supabase.labgrid.net/auth/v1/.well-known/jwks.json` | `200` + `keys` array (ES256 after asymmetric migration) |
| `https://supabase.labgrid.net/auth/v1/.well-known/openid-configuration` | `200` + `issuer` / `jwks_uri` (patched Kong route in this chart) |
| `https://supabase.labgrid.net/.well-known/jwks.json` | `401` — wrong path (hits Studio) |
| `https://supabase.labgrid.net/auth/v1/.well-known/` | `401` — path must include `jwks.json` or `openid-configuration` |
- MinIO / storage `CreateContainerConfigError` on `supabase-s3` key `password` — ensure the chart includes the s3 `password` mapping (from `labgrid-supabase-minio-password`).
- MinIO `CrashLoopBackOff` with `file access denied` on `/data` — Chainguard MinIO runs as UID 65532; set `deployment.minio.podSecurityContext.fsGroup: 65532` (included in `values.yaml`) so Synology PVCs are group-writable.

## Tranzr app integration

After Supabase is healthy, update tranzr-gitops AKV keys (`supabase-url`, `supabase-key`, `tranzr-supabase-database-connection-string`) to point at this instance.

**JWT validation (api-gateway):** set `SUPABASE_JWT_ISSUER=https://supabase.labgrid.net/auth/v1`. OIDC discovery is at `/auth/v1/.well-known/openid-configuration`; JWKS at `/auth/v1/.well-known/jwks.json`.
