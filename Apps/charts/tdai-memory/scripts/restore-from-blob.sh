#!/usr/bin/env bash
# Restore TDAI Memory PVC data from Azure Blob backups created by the chart CronJob.
#
# Prerequisites:
#   - Chart synced (empty PVCs Bound)
#   - az CLI logged in OR SAS env set
#   - kubectl context pointing at the target cluster
#
# Usage:
#   # List recent backups
#   ./scripts/restore-from-blob.sh list
#
#   # Restore specific stamps (ISO UTC from blob name, e.g. 2026-08-24T030000Z)
#   CORE_TS=2026-08-24T030000Z HUB_TS=2026-08-24T030000Z ./scripts/restore-from-blob.sh restore
#
#   # Restore latest core + hub
#   ./scripts/restore-from-blob.sh restore-latest
#
# Env overrides:
#   NS, ACCOUNT, CONTAINER, CORE_PREFIX, HUB_PREFIX, SAS_TOKEN (or AZURE_STORAGE_SAS_TOKEN)
set -euo pipefail

NS="${NS:-tdai-memory-system}"
ACCOUNT="${ACCOUNT:-labgrid}"
CONTAINER="${CONTAINER:-tdai-memory-backup}"
CORE_PREFIX="${CORE_PREFIX:-core}"
HUB_PREFIX="${HUB_PREFIX:-hub}"
CORE_DEPLOY="${CORE_DEPLOY:-tdai-memory-core}"
HUB_DEPLOY="${HUB_DEPLOY:-tdai-memory-hub}"
CORE_PVC="${CORE_PVC:-tdai-memory-core-data}"
HUB_PVC="${HUB_PVC:-tdai-memory-hub-knowledge}"
WORK="${WORK:-/tmp/tdai-restore-$$}"

SAS_RAW="${SAS_TOKEN:-${AZURE_STORAGE_SAS_TOKEN:-}}"
if [[ -z "${SAS_RAW}" ]]; then
  echo "Set SAS_TOKEN or AZURE_STORAGE_SAS_TOKEN (container SAS for ${CONTAINER})" >&2
  exit 1
fi
SAS_RAW="${SAS_RAW#"${SAS_RAW%%[![:space:]]*}"}"
SAS_RAW="${SAS_RAW%"${SAS_RAW##*[![:space:]]}"}"
if [[ "${SAS_RAW}" == \?* ]]; then
  SAS="${SAS_RAW:1}"
else
  SAS="${SAS_RAW}"
fi

az_blob() {
  az storage blob "$@" \
    --account-name "${ACCOUNT}" \
    --container-name "${CONTAINER}" \
    --sas-token "${SAS}"
}

list_blobs() {
  local prefix="$1"
  az_blob list --prefix "${prefix}/" --query "[].{name:name,lastModified:properties.lastModified,size:properties.contentLength}" -o table
}

latest_blob() {
  local prefix="$1"
  az_blob list --prefix "${prefix}/" \
    --query "sort_by([].{name:name,t:properties.lastModified}, &t)[-1].name" -o tsv
}

download_blob() {
  local name="$1"
  local dest="$2"
  mkdir -p "$(dirname "${dest}")"
  echo "Downloading ${name} -> ${dest}"
  az_blob download --name "${name}" --file "${dest}"
}

restore_pvc() {
  local pvc="$1"
  local archive="$2"
  local pod="tdai-restore-$$-${pvc##*-}"

  kubectl -n "${NS}" get pvc "${pvc}" >/dev/null
  kubectl -n "${NS}" delete pod "${pod}" --ignore-not-found --wait=true 2>/dev/null || true
  kubectl -n "${NS}" run "${pod}" --restart=Never --image=busybox:1.36 \
    --overrides="$(cat <<EOF
{
  "spec": {
    "containers": [{
      "name": "restore",
      "image": "busybox:1.36",
      "command": ["sleep", "3600"],
      "volumeMounts": [{"name": "data", "mountPath": "/data"}]
    }],
    "volumes": [{
      "name": "data",
      "persistentVolumeClaim": {"claimName": "${pvc}"}
    }]
  }
}
EOF
)"
  kubectl -n "${NS}" wait --for=condition=Ready "pod/${pod}" --timeout=120s
  kubectl -n "${NS}" cp "${archive}" "${pod}:/tmp/restore.tgz"
  kubectl -n "${NS}" exec "${pod}" -- sh -c '
    set -e
    cd /data
    # Move existing contents aside
    mkdir -p /data/.restore-old
    for x in * .[!.]*; do
      [ "$x" = ".restore-old" ] && continue
      [ -e "$x" ] || continue
      mv "$x" /data/.restore-old/ 2>/dev/null || true
    done
    tar xzf /tmp/restore.tgz -C /data
    echo "Restored PVC root:"
    ls -la /data | head -40
  '
  kubectl -n "${NS}" delete pod "${pod}" --wait=true
}

cmd="${1:-}"
case "${cmd}" in
  list)
    echo "=== ${CORE_PREFIX}/ ==="
    list_blobs "${CORE_PREFIX}"
    echo
    echo "=== ${HUB_PREFIX}/ ==="
    list_blobs "${HUB_PREFIX}"
    ;;
  restore|restore-latest)
    mkdir -p "${WORK}"
    if [[ "${cmd}" == "restore-latest" ]]; then
      CORE_BLOB="$(latest_blob "${CORE_PREFIX}")"
      HUB_BLOB="$(latest_blob "${HUB_PREFIX}")"
    else
      : "${CORE_TS:?Set CORE_TS=... or use restore-latest}"
      : "${HUB_TS:?Set HUB_TS=... or use restore-latest}"
      CORE_BLOB="${CORE_PREFIX}/tdai-core-${CORE_TS}.tgz"
      HUB_BLOB="${HUB_PREFIX}/tdai-hub-${HUB_TS}.tgz"
    fi
    echo "Core blob: ${CORE_BLOB}"
    echo "Hub blob:  ${HUB_BLOB}"

    download_blob "${CORE_BLOB}" "${WORK}/core.tgz"
    download_blob "${HUB_BLOB}" "${WORK}/hub.tgz"

    echo "Scaling deployments to 0"
    kubectl -n "${NS}" scale "deploy/${CORE_DEPLOY}" --replicas=0
    kubectl -n "${NS}" scale "deploy/${HUB_DEPLOY}" --replicas=0
    kubectl -n "${NS}" rollout status "deploy/${CORE_DEPLOY}" --timeout=180s || true
    kubectl -n "${NS}" rollout status "deploy/${HUB_DEPLOY}" --timeout=180s || true

    restore_pvc "${CORE_PVC}" "${WORK}/core.tgz"
    restore_pvc "${HUB_PVC}" "${WORK}/hub.tgz"

    echo "Scaling deployments to 1"
    kubectl -n "${NS}" scale "deploy/${CORE_DEPLOY}" --replicas=1
    kubectl -n "${NS}" scale "deploy/${HUB_DEPLOY}" --replicas=1
    kubectl -n "${NS}" rollout status "deploy/${CORE_DEPLOY}" --timeout=180s
    kubectl -n "${NS}" rollout status "deploy/${HUB_DEPLOY}" --timeout=180s
    rm -rf "${WORK}"
    echo "Restore complete. Smoke: curl -fsS -H \"Authorization: Bearer \$TDAI_GATEWAY_BEARER\" https://memory.labgrid.net/health"
    ;;
  *)
    echo "Usage: $0 list | restore | restore-latest" >&2
    exit 1
    ;;
esac
