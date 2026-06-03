## Monitoring umbrella chart (LGTM+P)

Production observability for the **labgrid home cluster** (Argo CD). Hetzner Tranzr production uses the same stack layout but is deployed separately—see below.

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

### Deploy (labgrid)

| Item | Detail |
|------|--------|
| Mechanism | Argo CD `labgrid-production` ApplicationSet |
| Values | `values-production.yaml` |
| Release name | `monitoring` (namespace `monitoring-system`) |
| Grafana AKV keys | `labgrid-grafana-admin-user`, `labgrid-grafana-admin-password` |

### Hetzner (Tranzr production)

Not deployed from this chart. Configuration lives in [hetzner-k3s](https://github.com/tranz-r/hetzner-k3s) as Terraform `helm_release` resources under `resources/monitoring-*.tf` (same chart versions and behavior; Hetzner-specific storage, ingress hosts, and `tranzr-grafana-*` AKV keys).

When bumping dependency versions in `Chart.yaml` here, update the matching `version` fields in hetzner-k3s `monitoring-*.tf`.

### Spike / migration

Validated in `Apps/spike/monitoring-stack` (`monitoring-spike` namespace). See spike README for install/teardown.

### URLs

**Labgrid production**

- Grafana: https://grafana.labgrid.net
- Prometheus: https://prometheus.labgrid.net
- Alertmanager: https://alertmanager.labgrid.net

**Hetzner production**

- Grafana: https://grafana.tranzr.co.uk
- Prometheus: https://prometheus.tranzr.co.uk
- Alertmanager: https://alertmanager.tranzr.co.uk

### Alloy OTLP (in-cluster)

Application pods send OTLP to the Alloy Kubernetes Service (ports exposed via `alloy.alloy.extraPorts`):

- gRPC: `http://monitoring-alloy.monitoring-system.svc.cluster.local:4317`
- HTTP: `http://monitoring-alloy.monitoring-system.svc.cluster.local:4318`

Set on Tranzr workloads (see tranzr-gitops `observability` values):

- `OTEL_EXPORTER_OTLP_ENDPOINT=http://monitoring-alloy.monitoring-system.svc.cluster.local:4317`
- `OTEL_EXPORTER_OTLP_PROTOCOL=grpc`

### Upgrading (labgrid)

1. Bump dependency versions in `Chart.yaml`
2. Run `helm dependency update Apps/charts/monitoring`
3. Bump chart `version` and merge to `main`
4. Argo sync; align hetzner-k3s `monitoring-*.tf` chart versions if Hetzner should stay in step
