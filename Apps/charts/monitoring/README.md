## Monitoring Umbrella Chart (kube-prometheus-stack)

This chart bundles the upstream `prometheus-community/kube-prometheus-stack` providing a full monitoring stack: Prometheus Operator, Prometheus, Alertmanager, Grafana, node exporter, kube-state-metrics and default recording/alerting rules.

### Dependency

Declared in `Chart.yaml`:

```yaml
dependencies:
  - name: kube-prometheus-stack
    version: 65.0.0
    repository: https://prometheus-community.github.io/helm-charts
```

Update / vendor the dependency:

```bash
helm dependency update Apps/charts/monitoring
```

### Install

```bash
helm upgrade --install monitoring Apps/charts/monitoring -n monitoring --create-namespace
```

### Key Overrides (`values.yaml`)

- Retention: `kube-prometheus-stack.prometheus.prometheusSpec.retention` (default 15d here)
- Prometheus storage size: `kube-prometheus-stack.prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage`
- Alertmanager storage: `kube-prometheus-stack.alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage`
- Grafana persistence: `kube-prometheus-stack.grafana.persistence.size`
- Enable/disable components by toggling their `enabled` flag.

### Adding Custom Scrape Jobs

Provide your own secret with scrape configs and reference via `kube-prometheus-stack.prometheus.prometheusSpec.additionalScrapeConfigs`. Example:

```yaml
kube-prometheus-stack:
  prometheus:
    prometheusSpec:
      additionalScrapeConfigs:
        - job_name: custom-service
          static_configs:
            - targets: ["my-service.monitoring:8080"]
```

For larger configs, create a Secret and use `additionalScrapeConfigsSecret` (see upstream docs).

### Security / Credentials

Change `kube-prometheus-stack.grafana.adminPassword` via a secure values override or ExternalSecret in production.

### Upgrading

Adjust dependency version and bump chart `version`, then run `helm dependency update`.

### Disabling Grafana

```yaml
kube-prometheus-stack:
  grafana:
    enabled: false
```

### Removing Persistent Volumes

Delete the `storageSpec` / `storage` sections or override with smaller ephemeral settings (not recommended for production).
When changing dependency version bump chart `version` in `Chart.yaml` and run `helm dependency update` again.
