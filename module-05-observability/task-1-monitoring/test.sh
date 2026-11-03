#!/usr/bin/env bash
source "$(dirname "$0")/../../tests/lib.sh"
title "Module 05 / Task 1 — Monitoring (Prometheus, Grafana, Loki, Alloy)"

for app in kube-prometheus-stack loki alloy grafana-dashboards; do
  check "Argo CD app $app is Synced/Healthy" app_synced_healthy "$app"
done
check "all monitoring pods are Ready" kubectl -n monitoring wait --for=condition=Ready pod --all --timeout=60s

targets_up() {
  prom 'min by (job) (up{job=~"kubelet|node-exporter|kube-state-metrics"})' \
    | jq -e 'length == 3 and all(.[]; .value[1]=="1")'
}
check "Prometheus scrapes kubelet, node-exporter, kube-state-metrics" targets_up

check "Loki is ready" eval 'kubectl get --raw /api/v1/namespaces/monitoring/services/http:loki:3100/proxy/ready | grep -q ready'
eventually 120 "Loki has pod logs (Alloy)"           loki_has_data '{job="kubernetes-pods"}' 10
eventually 120 "Loki has Kubernetes events (Alloy)"  loki_has_data '{job="loki.source.kubernetes_events"}' 60

grafana_start
check "Grafana is up" grafana /api/health
for ds in prometheus loki; do
  check "Grafana datasource $ds is healthy" eval "grafana /api/datasources/uid/$ds/health | jq -e '.status==\"OK\"'"
done

finish
