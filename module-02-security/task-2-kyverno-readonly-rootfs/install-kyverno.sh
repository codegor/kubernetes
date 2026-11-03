#!/usr/bin/env bash
set -euo pipefail

helm repo add kyverno https://kyverno.github.io/kyverno/ >/dev/null
helm repo update kyverno >/dev/null
# Same chart version as the Argo CD Application (module-03-platform/task-1-gitops/apps/values.yaml):
# a Kyverno downgrade cannot read the TLS secret a newer version left behind.
helm upgrade --install kyverno kyverno/kyverno --version "3.9.*" -n kyverno --create-namespace --wait
