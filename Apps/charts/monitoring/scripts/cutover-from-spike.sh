#!/usr/bin/env bash
# Phase 4: After monitoring-system is healthy, remove spike namespace and orphaned cluster RBAC.
set -euo pipefail

echo "==> Uninstall spike release"
helm uninstall monitoring-spike -n monitoring-spike 2>/dev/null || echo "Spike release not found"

echo "==> Delete spike namespace"
kubectl delete namespace monitoring-spike --wait=true --timeout=300s 2>/dev/null || echo "Namespace already gone"

echo "==> Remove spike cluster RBAC (if helm uninstall left orphans)"
for cr in kps-spike-operator kps-spike-prometheus monitoring-spike-alloy monitoring-spike-grafana-clusterrole monitoring-spike-kube-state-metrics monitoring-spike-loki-clusterrole; do
  kubectl delete clusterrole,clusterrolebinding "$cr" --ignore-not-found 2>/dev/null || true
done
kubectl delete clusterrolebinding monitoring-spike-grafana-clusterrolebinding monitoring-spike-loki-clusterrolebinding monitoring-spike-alloy monitoring-spike-kube-state-metrics --ignore-not-found 2>/dev/null || true

echo ""
echo "Optional: remove DNS for grafana-spike / prometheus-spike / alertmanager-spike.labgrid.net"
echo "Production URLs: grafana.labgrid.net, prometheus.labgrid.net, alertmanager.labgrid.net"
