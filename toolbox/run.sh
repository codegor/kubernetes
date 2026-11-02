#!/usr/bin/env bash
# Runs a command (default: bash) in the toolbox container: kind, kubectl, helm, openssl.
# The kind kubeconfig is kept in ~/.kube-course on the host.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
docker build -q -t k8s-course-toolbox "$ROOT/toolbox" >/dev/null
mkdir -p "$HOME/.kube-course"
TTY=$([ -t 0 ] && echo -it || echo -i)
exec docker run --rm $TTY --network host \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$ROOT":/work -v "$HOME/.kube-course":/root/.kube \
  -w "/work/${SUBDIR:-}" k8s-course-toolbox "${@:-bash}"
