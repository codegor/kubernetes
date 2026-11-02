# Module 05 · Task 1 — Monitoring

Installed by Argo CD (`module-03-platform/task-1-gitops/apps/templates/monitoring.yaml`),
all in namespace `monitoring`:

| Application | What | Values |
|---|---|---|
| `kube-prometheus-stack` | Prometheus, Alertmanager, Grafana, node-exporter, kube-state-metrics | `kube-prometheus-stack-values.yaml` |
| `loki` | Log storage (single binary) | `loki-values.yaml` |
| `alloy` | Ships pod logs and Kubernetes Events to Loki | `alloy-values.yaml` |
| `grafana-dashboards` | Dashboard / alert ConfigMaps from task-2 and task-3 | — |

Grafana loads every ConfigMap labelled `grafana_dashboard: "1"` (dashboards) or
`grafana_alert: "1"` (alert rules) from any namespace.

## Open Grafana

```bash
kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80
# http://localhost:3000  admin / admin
```
