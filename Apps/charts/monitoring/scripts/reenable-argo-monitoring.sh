#!/usr/bin/env bash
# Re-enable Argo CD monitoring app after merging chart 0.3.0 to main.
set -euo pipefail

echo "==> Ensure chart is on main and Argo has synced"
echo "    argocd app get monitoring"
echo "    argocd app sync monitoring"
echo ""
echo "If application was deleted during spike:"
echo "    It is recreated automatically by Terraform ApplicationSet on next Apps/ apply"
echo "    Or sync labgrid-production ApplicationSet in Argo CD"
echo ""
echo "Verify:"
echo "  kubectl get pods -n monitoring-system"
echo "  curl -sI https://grafana.labgrid.net | head -5"
