## Monitoring umbrella chart (LGTM+P)

Production observability for the **labgrid home cluster** (Argo CD). Hetzner Tranzr production uses the same stack layout but is deployed separately—see below.

| Component | Chart | Role |
|-----------|-------|------|
| **kube-prometheus-stack** | prometheus-community | Prometheus + Alertmanager only (no kubelet/kube-state-metrics/node-exporter); dashboard ConfigMaps (`grafana.enabled: false`) |
| **grafana** | grafana.github.io | **Standalone** Grafana UI |
| **loki** | grafana.github.io | Log aggregation |
| **tempo** | grafana.github.io | Distributed tracing (monolithic) |
| **alloy** | grafana.github.io | DaemonSet: pod logs → Loki; OTLP → Tempo + Prometheus remote_write; Faro → Loki/Tempo |

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
- Faro (Drivers PWA staging): https://faro.tranzrmoves.com — Gateway API HTTPRoute on `labgrid-gateway` (VIP `192.168.1.205`); Cloudflare/NPM same pattern as `api.tranzrmoves.com`

**Hetzner production**

- Grafana: https://grafana.tranzzer.com
- Prometheus: https://prometheus.tranzzer.com
- Alertmanager: https://alertmanager.tranzzer.com
- Faro (Drivers PWA production): https://faro.tranzzer.com (configured in hetzner-k3s)

### Metrics strategy (app-focused)

**Disabled (cluster infra):** kubelet/cAdvisor, kube-state-metrics, node-exporter, control-plane ServiceMonitors, and related alert rules. This avoids high-cardinality per-container series filling the Prometheus PVC.

**Enabled:**

- **OTLP → Alloy → Prometheus remote_write** — primary path for application metrics (OpenTelemetry).
- **Opt-in ServiceMonitors** — label `prometheus-scrape: "true"` on any `ServiceMonitor` / `PodMonitor` you add to app charts.

Prometheus retention: **7d**, cap **45GiB**, PVC **80Gi** (production). Scrape interval **60s**.

### Logs strategy

Alloy collects pod logs from all namespaces **except** the infra denylist in `alloyLogs.namespaceDenylist` (`kube-system`, `monitoring-system`, `argocd`, etc.). Loki retention **7d** with ingestion rate limits.

### Alloy OTLP (in-cluster)

Application pods send OTLP to the Alloy Kubernetes Service (ports exposed via `alloy.alloy.extraPorts`):

- gRPC: `http://monitoring-alloy.monitoring-system.svc.cluster.local:4317`
- HTTP: `http://monitoring-alloy.monitoring-system.svc.cluster.local:4318`

Set on Tranzr workloads (see tranzr-gitops `observability` values):

- `OTEL_EXPORTER_OTLP_ENDPOINT=http://monitoring-alloy.monitoring-system.svc.cluster.local:4317`
- `OTEL_EXPORTER_OTLP_PROTOCOL=grpc`

### Alloy Faro (public browser RUM)

`faro.receiver` listens on Service port **12347**. Labgrid exposes it via **Gateway API** HTTPRoute (`alloyFaroGateway`) on shared `labgrid-gateway` listeners `http-tranzrmoves` / `https-tranzrmoves` (`*.tranzrmoves.com` / `tranzrmoves-wildcard-tls`). Host: `https://faro.tranzrmoves.com`. Point Hostinger Drivers PWA staging `NEXT_PUBLIC_FARO_URL` at `https://faro.tranzrmoves.com/collect`. DNS/NPM: same as staging API → Gateway VIP `192.168.1.205` (not ingress-nginx `.204`).

### Upgrading (labgrid)

1. Bump dependency versions in `Chart.yaml`
2. Run `helm dependency update Apps/charts/monitoring`
3. Bump chart `version` and merge to `main`
4. Argo sync; align hetzner-k3s `monitoring-*.tf` chart versions if Hetzner should stay in step

### Prometheus PVC recovery

If Prometheus was crash-looping on a full PVC, after sync you may still need to expand the existing claim (`kubectl edit pvc …` → `80Gi`) or clear old TSDB data once. New WAL volume should stay small with infra scraping disabled.

### Opt-in scrape example (app chart)

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: my-app
  labels:
    prometheus-scrape: "true"
spec:
  selector:
    matchLabels:
      app: my-app
  endpoints:
    - port: metrics
```
