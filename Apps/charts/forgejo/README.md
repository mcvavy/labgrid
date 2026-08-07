# Forgejo (Labgrid)

Self-hosted Forgejo on Labgrid using [forgejo-helm 17.1.4](https://artifacthub.io/packages/helm/forgejo-helm/forgejo) + CloudNativePG.

| Item                | Value                                                                                     |
| ------------------- | ----------------------------------------------------------------------------------------- |
| Argo app            | `forgejo` → namespace `forgejo-system`                                                    |
| HTTPS               | Gateway API HTTPRoute → `labgrid-gateway` (`*.labgrid.net` on VIP `192.168.1.205`)        |
| URL                 | https://git.labgrid.net                                                                   |
| SSH                 | Gateway TCP listener `forgejo-ssh` port **2222** → TCPRoute → `forgejo-ssh:22`            |
| Postgres            | CNPG cluster `forgejo-pgcluster` (v17), backups to Azure Blob                             |
| Cache/session/queue | Platform Redis `redis.redis-system:6379`                                                  |
| SMTP                | Azure Communication Services (`smtp.azurecomm.net:587`)                                   |
| Admin user          | AKV `forgejo-admin-username` / `forgejo-admin-password` (not username `admin` — reserved) |

## Prerequisites (manual)

1. **Base first (required for SSH):** apply `Base/Operators` (experimental `TCPRoute` CRD) and `Base` gateway (NGF `gwAPIExperimentalFeatures.enable` + `forgejo-ssh` TCP listener on port 2222) **before** syncing this app. Without that, the Forgejo `TCPRoute` will not Accept.
2. **DNS / HTTPS:** `git.labgrid.net` → Gateway VIP `192.168.1.205` (same path as other Gateway apps / NPM → `.205`). TLS comes from Gateway wildcard `labgrid-wildcard-tls` (no per-app Ingress cert).
3. **SSH reachability:** clients use `git@git.labgrid.net:2222:...` or `ssh://git@git.labgrid.net:2222/...`. LAN must reach `192.168.1.205:2222`. WAN needs firewall/port-forward; NPM does not proxy SSH.
4. **Azure Blob:** container `forgejo-pg-backup` on storage account `labgrid`.
5. **Azure Key Vault** secrets:
   - `forgejo-pg-backup-sas-token` — SAS for that container (same pattern as `linkding-pg-backup-sas-token`)
   - `forgejo-admin-username` — e.g. `forgejoadmin`
   - `forgejo-admin-password`
   - Reuse existing: `labgrid-storage-account-name`, `acs-smtp-username`, `acs-smtp-password`, `platform-redis-password`
6. **ACS sender:** chart defaults `FROM` to `git@tranzrmoves.com`. That address must be verified on ACS, **or** change `smtp.from` and `forgejo.gitea.config.mailer.FROM` in `values-production.yaml` to an already verified sender (Labgrid supabase uses `testing@tranzrmoves.com`).
7. **Operators:** CNPG + External Secrets already installed via `Base/Operators` (no new operator chart).
8. **Do not sync until** Base Gateway TCP + AKV/blob/DNS above exist — ApplicationSet will pick up `Apps/charts/forgejo` on `main` and deploy to `forgejo-system`.

## Dependencies

```bash
cd Apps/charts/forgejo
helm dependency update
```

## Deploy

1. Apply Base Operators + Base gateway (experimental TCPRoute + NGF experimental flag + TCP listener).
2. Push to `main` under `Apps/charts/forgejo` — ApplicationSet syncs `values-production.yaml`.

Ensure **Operators** (CNPG/ESO) and Gateway are healthy before the app syncs. Forgejo may restart until `forgejo-pgcluster-rw` is Ready.

## Networking notes

- Ingress is **disabled**; HTTPS uses chart `httpRoute` only.
- SSH advertised port is **2222** (`SSH_PORT`); Service remains ClusterIP port **22** (rootless pod listens on 2222 internally).
- TCP has no hostname: port `2222` on `labgrid-gateway` is reserved for Forgejo SSH.
- Forgejo Actions disabled (`actions.ENABLED: false`).
- Username `admin` is reserved; use `forgejoadmin` (or other non-reserved).
- PVC name from upstream chart: `gitea-shared-storage`.
