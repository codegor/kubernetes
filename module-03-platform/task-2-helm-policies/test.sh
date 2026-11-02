#!/usr/bin/env bash
source "$(dirname "$0")/../../tests/lib.sh"
cd "$(dirname "$0")"
title "Module 03 / Task 2 — Module 02 as a Helm chart"

CHART=course-policies

check "helm lint" helm lint $CHART

count() { # kind [helm args...]
  local kind=$1; shift
  helm template t $CHART "$@" | grep -c "^kind: $kind$"
}
check "renders 4 Namespaces"     eval '[ "$(count Namespace)" = 4 ]'
check "renders 9 RoleBindings"   eval '[ "$(count RoleBinding)" = 9 ]'
check "renders 2 ClusterPolicies" eval '[ "$(count ClusterPolicy)" = 2 ]'
check "no ClusterRoleBinding / cluster-admin" \
  eval '! helm template t $CHART | grep -E "kind: ClusterRoleBinding|name: (cluster-)?admin$"'

STUDENT04='[{"user":"student01","namespace":"student01"},{"user":"student02","namespace":"student02","readOnlyNamespaces":["student01","default"]},{"user":"student03","namespace":"student03"},{"user":"student04","namespace":"student04"}]'
added() { helm template t $CHART --set-json "students=$STUDENT04"; }
check "adding student04 in values -> namespace"                 eval 'added | grep -q "name: student04$"'
check "adding student04 in values -> RoleBinding student04-edit" eval 'added | grep -q "name: student04-edit"'
check "adding student04 in values -> mentor-edit in student04"  eval '[ "$(added | grep -c "name: mentor-edit")" = 5 ]'
check "adding student04 in values -> person=student rule"       eval 'added | grep -A14 "name: person-student" | grep -q "student04"'
check "failureAction comes from values" \
  eval 'helm template t $CHART --set policies.readonlyRootFilesystem.failureAction=Enforce | grep -q "failureAction: Enforce"'
check "policies can be switched off" \
  eval '[ "$(count ClusterPolicy --set policies.personLabel.enabled=false)" = 1 ]'

live_rb() { [ "$(kubectl get rolebinding -A -l app.kubernetes.io/part-of=course-policies --no-headers | wc -l)" = 9 ]; }
check "cluster: 9 RoleBindings from the chart" live_rb
for p in require-readonly-root-filesystem add-person-label; do
  check "cluster: ClusterPolicy $p comes from the chart" \
    has_label clusterpolicy/$p "" app.kubernetes.io/part-of course-policies
done
check "cluster: Argo CD app course-policies is Synced/Healthy" app_synced_healthy course-policies

finish
