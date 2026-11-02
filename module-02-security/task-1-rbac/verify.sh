#!/usr/bin/env bash
# Checks every RBAC rule from the task with the users' own kubeconfigs.
set -uo pipefail
cd "$(dirname "$0")"

FAIL=0
check() { # user verb resource namespace expected(yes|no)
  local got
  got=$(kubectl --kubeconfig "out/$1.kubeconfig" auth can-i "$2" "$3" -n "$4" 2>/dev/null)
  if [ "$got" = "$5" ]; then
    printf 'ok    %-10s %-7s %-12s in %-10s -> %s\n' "$1" "$2" "$3" "$4" "$got"
  else
    printf 'FAIL  %-10s %-7s %-12s in %-10s -> %s (want %s)\n' "$1" "$2" "$3" "$4" "$got" "$5"
    FAIL=1
  fi
}
check_cluster_admin() { # user
  local got
  got=$(kubectl --kubeconfig "out/$1.kubeconfig" auth can-i '*' '*' --all-namespaces 2>/dev/null)
  if [ "$got" = no ]; then echo "ok    $1 is not cluster-admin"; else echo "FAIL  $1 is cluster-admin"; FAIL=1; fi
}

for ns in student01 student02 student03; do
  check mentor create deployments "$ns" yes
  check mentor delete pods "$ns" yes
done
check mentor create deployments kube-system no

check student01 create deployments student01 yes
check student01 get pods student02 no
check student01 get pods student03 no
check student01 get pods default no

check student03 create deployments student03 yes
check student03 get pods student01 no
check student03 get pods default no

check student02 get pods student01 yes
check student02 create pods student01 no
check student02 delete pods student01 no
check student02 get pods default yes
check student02 create pods default no
check student02 get pods student03 no

for u in mentor student01 student02 student03; do
  check_cluster_admin "$u"
  check "$u" create rolebindings "$u" no
done

exit $FAIL
