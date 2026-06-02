#!/usr/bin/env bash
# Phase 0: Suspend Argo CD monitoring app before installing the spike stack.
# Run with a kubeconfig pointed at the labgrid cluster.
set -euo pipefail

ARGO_NS="${ARGO_NS:-argocd}"
APP_NAME="${APP_NAME:-monitoring}"
TARGET_NS="${TARGET_NS:-monitoring-system}"

echo "==> Disabling auto-sync on Argo CD application '${APP_NAME}' (if present)"
if kubectl get application "${APP_NAME}" -n "${ARGO_NS}" &>/dev/null; then
  argocd app set "${APP_NAME}" --sync-policy none 2>/dev/null || \
    kubectl patch application "${APP_NAME}" -n "${ARGO_NS}" \
      --type merge -p '{"spec":{"syncPolicy":null}}' || true
  echo "    Delete the application (resources optional):"
  echo "    argocd app delete ${APP_NAME} --cascade"
else
  echo "    Application '${APP_NAME}' not found in ${ARGO_NS}; skip or adjust APP_NAME."
fi

echo ""
echo "==> Optional: remove existing monitoring-system workloads"
echo "    kubectl delete namespace ${TARGET_NS} --wait=false"
echo ""
echo "==> Prerequisites checklist"
echo "    - ClusterSecretStore azure-kv-cluster-store exists"
echo "    - StorageClass synology-iscsi-delete-wffc exists"
echo "    - Ingress class nginx + cert-manager ClusterIssuer letsencrypt-production"
echo "    - AKV keys: labgrid-grafana-admin-user, labgrid-grafana-admin-password"
echo ""
echo "Phase 0 complete. Install spike with:"
echo "  helm dependency update Apps/spike/monitoring-stack"
echo "  helm upgrade --install monitoring-spike Apps/spike/monitoring-stack \\"
echo "    -n monitoring-spike --create-namespace \\"
echo "    -f Apps/spike/monitoring-stack/values-labgrid-spike.yaml"
