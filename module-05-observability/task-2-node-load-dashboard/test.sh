#!/usr/bin/env bash
source "$(dirname "$0")/../../tests/lib.sh"
title "Module 05 / Task 2 — Dashboard: node load by student namespace"

UID_=student-node-load

check "dashboard ConfigMap is labelled for Grafana" \
  has_label configmap/dashboard-student-node-load monitoring grafana_dashboard 1
grafana_start
eventually 60 "Grafana has dashboard $UID_" grafana /api/dashboards/uid/$UID_

# Some load, so every panel has data.
for ns in student01 student02 student03; do
  on_exit "kubectl -n $ns delete pod hw-test-load --wait=false"
  kubectl -n $ns run hw-test-load --image=busybox:1.36 --restart=Never -l $TEST_LABEL \
    -- sh -c 'while :; do :; done' >/dev/null
done

ns_variable() {
  prom 'kube_namespace_status_phase{namespace=~"student.*"}' \
    | jq -e '[.[].metric.namespace] | unique == ["student01","student02","student03"]'
}
check "namespace variable lists student01..03" ns_variable

# Every panel query, as Grafana loaded it, with the variables set to "All".
while IFS=$'\t' read -r panel expr; do
  expr=$(printf '%b' "$expr" | sed -e 's/\$namespace/student.*/g' -e 's/\$node/.*/g')
  eventually 180 "panel \"$panel\" returns data" prom_has_data "$expr"
done < <(grafana /api/dashboards/uid/$UID_ | jq -r '.dashboard.panels[] | .title as $t | .targets[] | [$t + " (" + .refId + ")", .expr] | @tsv')

per_node_and_ns() {
  prom 'sum by (node, namespace) (sum by (namespace, pod) (rate(container_cpu_usage_seconds_total{namespace=~"student.*", container!=""}[5m])) * on (namespace, pod) group_left(node) max by (namespace, pod, node) (kube_pod_info{namespace=~"student.*"}))' \
    | jq -e 'length > 0 and all(.[]; (.metric.node|length) > 0 and (.metric.namespace|startswith("student")))'
}
check "CPU series are split by node AND student namespace" per_node_and_ns

finish
