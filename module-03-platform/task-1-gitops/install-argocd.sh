#!/usr/bin/env bash
# Installs Argo CD and the root "app of apps". After this, the cluster follows Git.
# Usage: REPO_URL=https://github.com/<you>/<repo>.git [REVISION=main] ./install-argocd.sh
set -euo pipefail
cd "$(dirname "$0")"

: "${REPO_URL:?set REPO_URL to the Git URL of this repository}"
REVISION=${REVISION:-main}

helm repo add argo https://argoproj.github.io/argo-helm >/dev/null
helm repo update argo >/dev/null
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace \
  -f argocd-values.yaml --wait

sed -e "s|REPO_URL|$REPO_URL|g" -e "s|REVISION|$REVISION|g" root-app.yaml | kubectl apply -f -

echo
echo "Argo CD admin password:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo
echo "UI: kubectl -n argocd port-forward svc/argocd-server 8080:443  ->  https://localhost:8080"
