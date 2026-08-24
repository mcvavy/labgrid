# Rendered examples

`backup-manifests.rendered.yaml` is produced by:

```bash
./scripts/render-backup-manifests.sh
```

Regenerate before review if you change `templates/backup-*.yaml` or backup values. Do not apply this file by hand — Argo syncs the chart.
