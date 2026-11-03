#!/usr/bin/env bash
source "$(dirname "$0")/../../tests/lib.sh"
title "Module 04 / Task 2 — Kyverno: Istio sidecar for person=student"

check "ClusterPolicy student-istio-sidecar is Ready" \
  kubectl wait --for=condition=Ready clusterpolicy/student-istio-sidecar --timeout=30s
check "Argo CD app student-istio-sidecar is Synced/Healthy" app_synced_healthy student-istio-sidecar
ca_set() {
  [ -n "$(kubectl get mutatingwebhookconfiguration zz-istio-sidecar-injector-after-kyverno -o jsonpath='{.webhooks[0].clientConfig.caBundle}')" ]
}
check "after-Kyverno injector webhook has its caBundle from istiod" ca_set

has_sidecar() { # namespace
  dry_run_pod "$1" hw-test-mesh | jq -e '
    .metadata.labels.person=="student" and
    .metadata.labels["sidecar.istio.io/inject"]=="true" and
    any(.spec.containers[]; .name=="istio-proxy")'
}
no_sidecar() { # namespace
  dry_run_pod "$1" hw-test-mesh | jq -e 'all(.spec.containers[]; .name!="istio-proxy")'
}
for ns in student01 student02 student03; do
  check "$ns: pod gets person=student + istio-proxy" has_sidecar "$ns"
done
check "mentor: pod has no sidecar"  no_sidecar mentor
check "default: pod has no sidecar" no_sidecar default

# Kyverno policy order is random: repeat to catch an order-dependent miss.
repeat_ok() { local i ns; for i in $(seq 1 10); do for ns in student01 student02 student03; do has_sidecar "$ns" || return 1; done; done; }
check "30 more student pods: every one gets the sidecar" repeat_ok

# A real pod: the proxy must start and connect to istiod (2/2 Ready).
on_exit "kubectl -n student03 delete pod hw-test-mesh --wait=false"
kubectl -n student03 run hw-test-mesh --image=busybox:1.36 --restart=Never -l $TEST_LABEL -- sleep 3600 >/dev/null
eventually 180 "student03: real pod runs app + istio-proxy, both Ready" \
  eval 'kubectl -n student03 get pod hw-test-mesh -o json | jq -e "[.status.containerStatuses[] | select(.ready)] | length == 2"'

finish
