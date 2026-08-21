# Azure Key Vault setup (manual — do not commit secret values)

Labgrid is a **public** repo. Put secret **values** only in Azure Key Vault. Charts reference **key names** via ExternalSecret.

## GitHub App (preferred)

1. Create a GitHub App under the **`tranz-r`** organization (Settings → Developer settings → GitHub Apps).
2. Permissions:
   - **Actions**: Read
   - **Administration**: Read & write (self-hosted runners)
   - **Metadata**: Read
3. Install the App on the org (or all Tranzzer / labgrid repos that should use runners).
4. Create these Key Vault secrets (exact names used by `gha-runners` ExternalSecret):

| AKV secret name | Contents |
| --- | --- |
| `github-arc-app-id` | App ID (numeric string) |
| `github-arc-installation-id` | Installation ID (numeric string) |
| `github-arc-private-key` | Full PEM private key downloaded from the App |

## Temporary PAT fallback

If the App is not ready, store a fine-grained PAT as AKV secret `github-arc-pat` and change the ExternalSecret / scale-set secret mapping to use `github_token` instead of the three App keys (see `gha-runners` README). Rotate to the App ASAP.

## What stays on GitHub

Repo and Environment Actions secrets (Stripe, Azure SP, kubeconfig, etc.) are unchanged. They are injected into workflow jobs after a runner is assigned. They are **not** used to register ARC.
