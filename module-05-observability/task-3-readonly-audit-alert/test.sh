#!/usr/bin/env bash
source "$(dirname "$0")/../../tests/lib.sh"
title "Module 05 / Task 3 — Dashboard + alert: read-only root filesystem audit"

DASH=readonly-rootfs-audit
RULE=readonly-rootfs-audit-fail
POD=hw-test-audit-$RANDOM
NS=mentor

check "dashboard ConfigMap is labelled for Grafana" \
  has_label configmap/dashboard-readonly-rootfs-audit monitoring grafana_dashboard 1
check "alert ConfigMap is labelled for Grafana" \
  has_label configmap/alert-readonly-rootfs-audit monitoring grafana_alert 1

grafana_start
eventually 60 "Grafana has dashboard $DASH"  grafana /api/dashboards/uid/$DASH
eventually 60 "Grafana has alert rule $RULE" grafana /api/v1/provisioning/alert-rules/$RULE

# A fresh violation that the log pipeline must carry end to end.
on_exit "kubectl -n $NS delete pod $POD --wait=false"
kubectl -n $NS run $POD --image=busybox:1.36 --restart=Never -l $TEST_LABEL -- sleep 3600 >/dev/null
eventually 240 "Loki has the audit failure of $POD" \
  loki_has_data "{job=\"loki.source.kubernetes_events\"} |= \"$POD\" |= \"require-readonly-root-filesystem\" |= \"fail\"" 10
only_object_copy() {
  loki_range "{job=\"loki.source.kubernetes_events\"} |= \"$POD\" |= \"require-readonly-root-filesystem\" |= \"fail\" != \"kind=ClusterPolicy\"" 10 \
    | jq -e --arg ns $NS 'length > 0 and all(.[]; .stream.namespace==$ns)'
}
check "failure is counted under namespace $NS (ClusterPolicy copy dropped)" only_object_copy

# Every dashboard query returns data.
while IFS=$'\t' read -r panel expr; do
  expr=$(printf '%b' "$expr" | sed 's/\$__interval/30m/g')
  check "panel \"$panel\" returns data" loki_has_data "$expr" 30
done < <(grafana /api/dashboards/uid/$DASH | jq -r '.dashboard.panels[] | .title as $t | .targets[] | [$t + " (" + .refId + ")", .expr] | @tsv')

alert_firing() {
  grafana /api/prometheus/grafana/api/v1/rules \
    | jq -e 'any(.data.groups[].rules[]; .name=="Read-only root filesystem audit failed" and .state=="firing" and .health=="ok")'
}
eventually 180 "alert \"Read-only root filesystem audit failed\" is firing" alert_firing

finish
