#!/usr/bin/env bash
# Issues a client certificate per user through the Kubernetes CSR API and writes
# out/<user>.kubeconfig. Run with an admin kubeconfig (the kind one).
set -euo pipefail
cd "$(dirname "$0")"

USERS=(mentor student01 student02 student03)
OUT=out
mkdir -p "$OUT"

CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
SERVER=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' \
  | base64 -d > "$OUT/ca.crt"

for u in "${USERS[@]}"; do
  echo "==> $u"
  openssl genrsa -out "$OUT/$u.key" 2048 2>/dev/null
  # CN = user name. No O=system:masters, otherwise the user would be cluster-admin.
  openssl req -new -key "$OUT/$u.key" -out "$OUT/$u.csr" -subj "/CN=$u/O=course"

  kubectl delete csr "$u" --ignore-not-found >/dev/null
  cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $u
spec:
  request: $(base64 -w0 < "$OUT/$u.csr")
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 31536000
  usages: ["client auth"]
EOF
  kubectl certificate approve "$u" >/dev/null

  for _ in $(seq 1 30); do
    CERT=$(kubectl get csr "$u" -o jsonpath='{.status.certificate}')
    [ -n "$CERT" ] && break
    sleep 1
  done
  [ -n "$CERT" ] || { echo "certificate for $u was not issued" >&2; exit 1; }
  echo "$CERT" | base64 -d > "$OUT/$u.crt"

  KC="$OUT/$u.kubeconfig"
  rm -f "$KC"
  kubectl config --kubeconfig="$KC" set-cluster "$CLUSTER_NAME" \
    --server="$SERVER" --certificate-authority="$OUT/ca.crt" --embed-certs=true >/dev/null
  kubectl config --kubeconfig="$KC" set-credentials "$u" \
    --client-certificate="$OUT/$u.crt" --client-key="$OUT/$u.key" --embed-certs=true >/dev/null
  DEFAULT_NS=$([ "$u" = mentor ] && echo mentor || echo "$u")
  kubectl config --kubeconfig="$KC" set-context "$u@$CLUSTER_NAME" \
    --cluster="$CLUSTER_NAME" --user="$u" --namespace="$DEFAULT_NS" >/dev/null
  kubectl config --kubeconfig="$KC" use-context "$u@$CLUSTER_NAME" >/dev/null
done

echo
echo "Kubeconfigs:"
ls -1 "$OUT"/*.kubeconfig
