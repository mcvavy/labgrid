#!/usr/bin/env bash
# Copy archived Core data into the Labgrid PVC (run after Argo sync + PVC Bound).
# Usage: ARCHIVE=/tmp/tdai-memory-data.tgz ./scripts/migrate-data.sh
set -euo pipefail

NS="${NS:-tdai-memory-system}"
PVC="${PVC:-tdai-memory-core-data}"
DEPLOY="${DEPLOY:-tdai-memory-core}"
ARCHIVE="${ARCHIVE:-/tmp/tdai-memory-data.tgz}"
POD="tdai-migrate-$$"

if [[ ! -f "$ARCHIVE" ]]; then
  echo "Missing archive: $ARCHIVE" >&2
  echo "Create with: tar -C ~/agent-memory -czf /tmp/tdai-memory-data.tgz data" >&2
  exit 1
fi

kubectl -n "$NS" get pvc "$PVC" >/dev/null
kubectl -n "$NS" scale "deploy/${DEPLOY}" --replicas=0

kubectl -n "$NS" delete pod "$POD" --ignore-not-found --wait=true 2>/dev/null || true
kubectl -n "$NS" run "$POD" --restart=Never --image=busybox:1.36 \
  --overrides="$(cat <<EOF
{
  "spec": {
    "containers": [{
      "name": "migrate",
      "image": "busybox:1.36",
      "command": ["sleep", "3600"],
      "volumeMounts": [{"name": "data", "mountPath": "/data"}]
    }],
    "volumes": [{
      "name": "data",
      "persistentVolumeClaim": {"claimName": "${PVC}"}
    }]
  }
}
EOF
)"

kubectl -n "$NS" wait --for=condition=Ready "pod/${POD}" --timeout=120s
kubectl -n "$NS" cp "$ARCHIVE" "${POD}:/tmp/tdai-memory-data.tgz"
kubectl -n "$NS" exec "$POD" -- sh -c '
  set -e
  cd /data
  tar xzf /tmp/tdai-memory-data.tgz
  if [ -d data ] && [ ! -d tdai-memory ]; then
    mkdir -p tdai-memory
    mv data/* tdai-memory/ 2>/dev/null || true
    rmdir data 2>/dev/null || true
  fi
  # Host bind-mount was ~/agent-memory/data → /data/tdai-memory; archive root is often "data/"
  if [ -d data ] && [ -d tdai-memory ]; then
    echo "both data/ and tdai-memory/ present — inspect before continuing" >&2
    ls -la
    exit 1
  fi
  ls -la
  ls -la tdai-memory 2>/dev/null || ls -la
'

kubectl -n "$NS" delete pod "$POD" --wait=true
kubectl -n "$NS" scale "deploy/${DEPLOY}" --replicas=1
kubectl -n "$NS" rollout status "deploy/${DEPLOY}" --timeout=180s
echo "Migration complete. Smoke: curl -fsS -H \"Authorization: Bearer \$TDAI_GATEWAY_BEARER\" https://memory.labgrid.net/health"
