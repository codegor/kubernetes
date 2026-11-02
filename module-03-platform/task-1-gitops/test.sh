#!/usr/bin/env bash
source "$(dirname "$0")/../../tests/lib.sh"
title "Module 03 / Task 1 — GitOps (Argo CD)"

check "Argo CD pods are Ready" kubectl -n argocd wait --for=condition=Ready pod --all --timeout=60s

root_automated() {
  kubectl -n argocd get application root -o json \
    | jq -e '.spec.syncPolicy.automated.prune and .spec.syncPolicy.automated.selfHeal'
}
check "root app syncs automatically (prune + selfHeal)" root_automated

for app in $(kubectl -n argocd get applications -o jsonpath='{.items[*].metadata.name}'); do
  eventually 120 "application $app is Synced/Healthy" app_synced_healthy "$app"
done

# Self-heal: a resource deleted by hand comes back from Git.
kubectl -n student01 delete rolebinding student01-edit --wait=true >/dev/null 2>&1
eventually 240 "deleted RoleBinding student01/student01-edit is restored by Argo CD" \
  kubectl -n student01 get rolebinding student01-edit

finish
