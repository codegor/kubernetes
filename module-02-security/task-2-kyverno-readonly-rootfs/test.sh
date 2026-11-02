#!/usr/bin/env bash
source "$(dirname "$0")/../../tests/lib.sh"
title "Module 02 / Task 2 — Kyverno: read-only root filesystem (Audit)"

POLICY=require-readonly-root-filesystem
# mentor namespace: no Istio sidecar there, whose istio-init would itself fail the check.
NS=mentor

check "ClusterPolicy $POLICY is Ready" \
  kubectl wait --for=condition=Ready clusterpolicy/$POLICY --timeout=30s
audit_mode() { [ "$(kubectl get clusterpolicy $POLICY -o jsonpath='{.spec.rules[0].validate.failureAction}')" = Audit ]; }
check "failureAction is Audit" audit_mode

on_exit "kubectl -n $NS delete pod -l $TEST_LABEL --wait=false"
check "pod WITHOUT readOnlyRootFilesystem is admitted (audit, not enforce)" \
  kubectl -n $NS run hw-test-ro-bad --image=busybox:1.36 --restart=Never -l $TEST_LABEL -- sleep 3600
check "pod WITH readOnlyRootFilesystem is admitted" kubectl -n $NS apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: hw-test-ro-good
  labels: {hw-test: "1"}
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sleep", "3600"]
      securityContext: {readOnlyRootFilesystem: true}
EOF

report_result() { # pod expected
  kubectl -n $NS get policyreport -o json | jq -e --arg p "$1" --arg r "$2" '
    any(.items[] | select(.scope.name==$p) | .results[]?; .policy=="require-readonly-root-filesystem" and .result==$r)'
}
eventually 120 "PolicyReport: hw-test-ro-bad = fail"  report_result hw-test-ro-bad fail
eventually 120 "PolicyReport: hw-test-ro-good = pass" report_result hw-test-ro-good pass

violation_event() {
  kubectl -n $NS get events --field-selector reason=PolicyViolation,involvedObject.name=hw-test-ro-bad -o json \
    | jq -e 'any(.items[]; .message|test("require-readonly-root-filesystem.*fail"))'
}
eventually 120 "PolicyViolation event on hw-test-ro-bad" violation_event

finish
