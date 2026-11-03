#!/usr/bin/env bash
source "$(dirname "$0")/../../tests/lib.sh"
cd "$(dirname "$0")"
title "Module 02 / Task 1 — namespaces, kubeconfigs, RBAC"

for ns in mentor student01 student02 student03; do
  check "namespace $ns exists" kubectl get namespace "$ns"
done

if ! ls out/*.kubeconfig >/dev/null 2>&1; then ./make-kubeconfigs.sh >/dev/null; fi
for u in mentor student01 student02 student03; do
  check "kubeconfig for $u works" kubectl --kubeconfig "out/$u.kubeconfig" auth whoami
done

as() { local u=$1; shift; kubectl --kubeconfig "out/$u.kubeconfig" "$@"; }

check     "student01 creates a ConfigMap in student01"      as student01 -n student01 create configmap hw-test-rbac
check     "student01 deletes it again"                      as student01 -n student01 delete configmap hw-test-rbac
check_not "student01 cannot read student02"                 as student01 -n student02 get pods
check     "student02 reads pods in student01"               as student02 -n student01 get pods
check     "student02 reads pods in default"                 as student02 -n default get pods
check_not "student02 cannot create in student01"            as student02 -n student01 create configmap hw-test-rbac
check_not "student02 cannot create in default"              as student02 -n default create configmap hw-test-rbac
check_not "student02 cannot read secrets in student01 (RO)" as student02 -n student01 get secrets
check     "mentor creates a ConfigMap in student03"         as mentor -n student03 create configmap hw-test-rbac
check     "mentor deletes it again"                         as mentor -n student03 delete configmap hw-test-rbac
check_not "mentor cannot touch kube-system"                 as mentor -n kube-system get pods

no_cluster_bindings() {
  kubectl get clusterrolebindings -o json | jq -e '
    [.items[] | select(any(.subjects[]?; .kind=="User" and
      (.name=="mentor" or (.name|test("^student0[1-3]$")))))] | length == 0'
}
check "no ClusterRoleBinding for mentor/students" no_cluster_bindings

echo "  -- full permission matrix (verify.sh):"
if ./verify.sh | sed 's/^/     /'; then ok "verify.sh matrix"; else bad "verify.sh matrix"; fi

finish
