# Module 05 · Task 3 — Dashboard and alert: read-only root filesystem audit failures

Kyverno (`require-readonly-root-filesystem`, Audit) records each failure as a Kubernetes Event
`reason=PolicyViolation` on the pod, message
`policy require-readonly-root-filesystem/check-readonly-root-filesystem fail: ...`.
Alloy ships Events to Loki as a log stream (`job="loki.source.kubernetes_events"`).

| File | What |
|---|---|
| `dashboard-configmap.yaml` | Dashboard **Kyverno — read-only root filesystem audit**: failure count, failures per namespace, the log lines |
| `alert-rule-configmap.yaml` | Grafana alert **Read-only root filesystem audit failed**: fires when the Loki query finds ≥ 1 failure in 5 min |

LogQL:

```logql
sum(count_over_time({job="loki.source.kubernetes_events"} |= "require-readonly-root-filesystem" |= "fail" [5m])) > 0
```

## Check

```bash
kubectl apply -f ../../module-02-security/task-2-kyverno-readonly-rootfs/test-pods.yaml
```

Within ~1–2 minutes the dashboard shows the `rootfs-bad` pod and the alert goes to
*Firing* (Grafana → Alerting → Alert rules → folder *Kyverno*). Contact point: Grafana default;
add Slack / Telegram / e-mail in Grafana → Alerting → Contact points.
