#!/usr/bin/env bash
# Copy archived Core data into the Labgrid PVC (run after Argo sync + PVC Bound).
# Host layout: ~/agent-memory/data is bind-mounted as /data/tdai-memory in Core.
# Chart mounts the PVC at /data/tdai-memory, so archive contents of "data/" land at PVC root.
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
kubectl -n "$NS" rollout status "deploy/${DEPLOY}" --timeout=120s || true

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
  # Preserve any first-boot empty store, then replace with host archive contents
  rm -rf /data/.migrate-old
  mkdir -p /data/.migrate-old
  for x in * .[!.]*; do
    [ "$x" = ".migrate-old" ] && continue
    [ -e "$x" ] || continue
    mv "$x" /data/.migrate-old/ 2>/dev/null || true
  done
  mkdir -p /tmp/extract
  tar xzf /tmp/tdai-memory-data.tgz -C /tmp/extract
  if [ -d /tmp/extract/data ]; then
    cp -a /tmp/extract/data/. /data/
  else
    cp -a /tmp/extract/. /data/
  fi
  rm -rf /tmp/extract
  echo "PVC root after migrate:"
  ls -la /data
  echo "sample:"
  ls -la /data/conversations /data/profiles /data/vectors.db 2>/dev/null || ls -la /data | head -20
'

kubectl -n "$NS" delete pod "$POD" --wait=true
kubectl -n "$NS" scale "deploy/${DEPLOY}" --replicas=1
kubectl -n "$NS" rollout status "deploy/${DEPLOY}" --timeout=180s
echo "Migration complete. Smoke: curl -fsS -H \"Authorization: Bearer \$TDAI_GATEWAY_BEARER\" https://memory.labgrid.net/health"
