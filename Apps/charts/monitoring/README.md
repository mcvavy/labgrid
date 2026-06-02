## Monitoring umbrella chart (LGTM+P)

Production observability for labgrid (and Hetzner via `values-hetzner.yaml` when added):

| Component | Chart | Role |
|-----------|-------|------|
| **kube-prometheus-stack** | prometheus-community | Prometheus, Alertmanager, node-exporter, kube-state-metrics, dashboard ConfigMaps (`grafana.enabled: false`) |
| **grafana** | grafana.github.io | **Standalone** Grafana UI |
| **loki** | grafana.github.io | Log aggregation |
| **tempo** | grafana.github.io | Distributed tracing (monolithic) |
| **alloy** | grafana.github.io | DaemonSet: pod logs → Loki; OTLP → Tempo + Prometheus remote_write |

### Dependencies

```bash
helm dependency update Apps/charts/monitoring
```

### Argo CD

Deployed by `labgrid-production` ApplicationSet: app `monitoring` → namespace `monitoring-system`, values file `values-production.yaml`.

**Helm release name must be `monitoring`** (matches ApplicationSet `{{path.basename}}`).

### Spike / migration

Validated in `Apps/spike/monitoring-stack` (`monitoring-spike` namespace). See spike README for install/teardown.

### URLs (labgrid production)

- Grafana: https://grafana.labgrid.net
- Prometheus: https://prometheus.labgrid.net
- Alertmanager: https://alertmanager.labgrid.net

### Alloy OTLP (in-cluster)

Apps can send OTLP to Alloy DaemonSet pods on nodes, or a Service if added later:

- gRPC: `4317`, HTTP: `4318` on alloy pods in `monitoring-system`

### Upgrading

Bump dependency versions in `Chart.yaml`, run `helm dependency update`, bump chart `version`, merge to `main`.
