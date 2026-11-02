#!/usr/bin/env bash
source "$(dirname "$0")/../../tests/lib.sh"
title "Module 04 / Task 1 — Istio (sidecar mode)"

check "Argo CD app istio-base is Synced/Healthy" app_synced_healthy istio-base
check "Argo CD app istiod is Synced/Healthy"     app_synced_healthy istiod
check "istiod is Available" kubectl -n istio-system wait --for=condition=Available deploy/istiod --timeout=60s
for crd in virtualservices.networking.istio.io destinationrules.networking.istio.io \
           peerauthentications.security.istio.io; do
  check "CRD $crd" kubectl get crd "$crd"
done
check "sidecar injector webhook exists" kubectl get mutatingwebhookconfiguration istio-sidecar-injector
check_not "no ztunnel (not ambient mode)" eval '[ -n "$(kubectl get daemonset -A -l app=ztunnel -o name)" ]'

finish
