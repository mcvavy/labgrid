#!/usr/bin/env bash
# Deploy monitoring chart 0.3.0 to monitoring-system (replaces legacy stack).
set -euo pipefail

CHART_DIR="${CHART_DIR:-Apps/charts/monitoring}"
NS="${NS:-monitoring-system}"
RELEASE="${RELEASE:-monitoring}"

cd "$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

echo "==> Update chart dependencies"
helm dependency update "${CHART_DIR}"

echo "==> Install/upgrade release '${RELEASE}' in ${NS}"
helm upgrade --install "${RELEASE}" "${CHART_DIR}" \
  -n "${NS}" --create-namespace \
  -f "${CHART_DIR}/values-production.yaml" \
  --timeout 20m

echo "==> If install fails on ClusterRole ownership, delete legacy monitoring cluster RBAC:"
echo "    monitoring-alloy, monitoring-kube-prometheus-*, monitoring-grafana-clusterrole, monitoring-loki-clusterrole"

echo "==> Remove duplicate Prometheus CRs from a prior kube-prometheus-stack Grafana subchart (if present)"
kubectl delete prometheus monitoring-kube-prometheus-prometheus -n "${NS}" --ignore-not-found
kubectl delete alertmanager monitoring-kube-prometheus-alertmanager -n "${NS}" --ignore-not-found
kubectl delete statefulset monitoring-grafana -n "${NS}" --ignore-not-found
kubectl delete deployment monitoring-kube-prometheus-operator -n "${NS}" --ignore-not-found

echo "==> Run validation"
kubectl get pods -n "${NS}"
kubectl get ingress -n "${NS}"

echo "Done. Open https://grafana.labgrid.net"
