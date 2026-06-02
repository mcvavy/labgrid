# Monitoring stack spike (LGTM+P)

Throwaway Helm umbrella chart for validating a **standalone Grafana** plus **kube-prometheus-stack** (no bundled Grafana), **Loki**, **Tempo**, and **Grafana Alloy** before migrating settings into [`Apps/charts/monitoring`](../../charts/monitoring).

**Not** deployed by Argo (`Apps/charts/*` ApplicationSet). Install manually.

## Architecture

- **kube-prometheus-stack** (`fullnameOverride: kps-spike`): Prometheus, Alertmanager, node-exporter, kube-state-metrics, dashboard ConfigMaps; `grafana.enabled: false`
- **grafana** (standalone): UI at `grafana-spike.labgrid.net`, datasources for Prometheus/Loki/Tempo
- **loki**: log storage
- **tempo**: trace storage (monolithic)
- **alloy**: DaemonSet — pod logs → Loki; OTLP → Tempo + Prometheus remote_write

## Phase 0 — Suspend existing monitoring

```bash
chmod +x Apps/spike/monitoring-stack/scripts/phase0-suspend-monitoring.sh
./Apps/spike/monitoring-stack/scripts/phase0-suspend-monitoring.sh
# Then delete/suspend Argo app monitoring and optionally monitoring-system namespace.
```

## Install

```bash
cd /path/to/labgrid
helm dependency update Apps/spike/monitoring-stack
helm upgrade --install monitoring-spike Apps/spike/monitoring-stack \
  -n monitoring-spike --create-namespace \
  -f Apps/spike/monitoring-stack/values-labgrid-spike.yaml
```

Release name **must** be `monitoring-spike` (service DNS in values depend on it).

## Validation checklist

```bash
kubectl get pods -n monitoring-spike
kubectl get pvc -n monitoring-spike
kubectl get ingress -n monitoring-spike
```

- https://grafana-spike.labgrid.net — datasources Prometheus, Loki, Tempo green
- Explore → Loki: `{namespace="tranzr-moves-staging"} |= ""` (or your workload namespace)
- https://prometheus-spike.labgrid.net — Targets up (prometheus, node-exporter, alloy, …)
- https://alertmanager-spike.labgrid.net — UI loads

## Teardown (after migration to monitoring-system)

```bash
helm uninstall monitoring-spike -n monitoring-spike
kubectl delete namespace monitoring-spike
```

## Migrate

Copy working values into `Apps/charts/monitoring` and re-enable Argo application `monitoring` → `monitoring-system`. See repo plan / chart README.
