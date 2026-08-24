#!/usr/bin/env bash
# Render backup-related Helm templates for PR review (no cluster apply).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
helm template tdai-memory "${ROOT}" \
  -f "${ROOT}/values.yaml" \
  -f "${ROOT}/values-production.yaml" \
  -n tdai-memory-system \
  --show-only templates/backup-rbac.yaml \
  --show-only templates/backup-external-secret.yaml \
  --show-only templates/backup-configmap.yaml \
  --show-only templates/backup-cronjob.yaml
