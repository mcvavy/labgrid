#!/usr/bin/env bash
# Post-install validation for monitoring-spike namespace.
set -euo pipefail

NS="${NS:-monitoring-spike}"

echo "==> Pods in ${NS}"
kubectl get pods -n "${NS}" -o wide

echo ""
echo "==> PVCs"
kubectl get pvc -n "${NS}"

echo ""
echo "==> Ingress"
kubectl get ingress -n "${NS}"

echo ""
echo "==> ExternalSecret / Grafana admin secret"
kubectl get externalsecret -n "${NS}" 2>/dev/null || true
kubectl get secret labgrid-monitoring-credentials -n "${NS}" 2>/dev/null || echo "WARN: labgrid-monitoring-credentials not ready yet"

echo ""
echo "==> Prometheus remote-write receiver"
kubectl get prometheus -n "${NS}" -o yaml 2>/dev/null | grep -i enableRemoteWriteReceiver || true

echo ""
echo "Manual checks:"
echo "  - https://grafana-spike.labgrid.net"
echo "  - https://prometheus-spike.labgrid.net/targets"
echo "  - Grafana Explore Loki: {namespace=\"tranzr-moves-staging\"}"
