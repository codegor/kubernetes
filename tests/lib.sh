# Shared helpers for module-*/task-*/test.sh. Source it, call checks, end with `finish`.
set -uo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
PASS=0
FAIL=0
CLEANUP=()
TEST_LABEL=hw-test=1

if [ -t 1 ]; then G=$'\033[32m'; R=$'\033[31m'; B=$'\033[1m'; N=$'\033[0m'; else G= R= B= N=; fi

title() { echo; echo "${B}== $*${N}"; }
ok()    { echo "  ${G}ok${N}    $*"; PASS=$((PASS + 1)); }
bad()   { echo "  ${R}FAIL${N}  $*"; FAIL=$((FAIL + 1)); }

# check "description" command...      -> ok when the command succeeds
check() {
  local desc=$1; shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else bad "$desc"; fi
}

# check_not "description" command...  -> ok when the command fails
check_not() {
  local desc=$1; shift
  if "$@" >/dev/null 2>&1; then bad "$desc"; else ok "$desc"; fi
}

# eventually <seconds> "description" command...  -> retries every 5s until success or timeout
eventually() {
  local timeout=$1 desc=$2; shift 2
  local deadline=$((SECONDS + timeout))
  until "$@" >/dev/null 2>&1; do
    if [ $SECONDS -ge $deadline ]; then bad "$desc (gave up after ${timeout}s)"; return 1; fi
    sleep 5
  done
  ok "$desc"
}

on_exit() { CLEANUP+=("$*"); }
_cleanup() { local c; for c in "${CLEANUP[@]}"; do eval "$c" >/dev/null 2>&1; done; }
trap _cleanup EXIT

finish() {
  echo "  -- ${PASS} passed, ${FAIL} failed"
  [ "$FAIL" -eq 0 ]
}

# --- Kubernetes helpers ---------------------------------------------------------------

# Pod as the API server would store it (all mutating webhooks run), nothing is created.
dry_run_pod() { # namespace name [label=value,...]
  local labels=${3:+--labels=$3}
  kubectl run "$2" -n "$1" --image=busybox:1.36 --restart=Never $labels \
    --dry-run=server -o json -- sleep 3600
}

app_synced_healthy() { # argo application name
  [ "$(kubectl -n argocd get application "$1" -o jsonpath='{.status.sync.status}/{.status.health.status}')" = "Synced/Healthy" ]
}

uri() { jq -rn --arg v "$1" '$v|@uri'; }

# Prometheus / Loki through the API server service proxy (no port-forward needed).
prom() { # promql -> JSON result array
  kubectl get --raw "/api/v1/namespaces/monitoring/services/http:kube-prometheus-stack-prometheus:9090/proxy/api/v1/query?query=$(uri "$1")" \
    | jq -c '.data.result'
}
prom_has_data() { [ "$(prom "$1" | jq 'length')" -gt 0 ]; }

loki() { # logql (instant) -> JSON result array
  kubectl get --raw "/api/v1/namespaces/monitoring/services/http:loki:3100/proxy/loki/api/v1/query?query=$(uri "$1")" \
    | jq -c '.data.result'
}
loki_range() { # logql over the last <minutes> (default 30) -> JSON result array
  local start=$(( ($(date +%s) - ${2:-30} * 60) * 1000000000 ))
  kubectl get --raw "/api/v1/namespaces/monitoring/services/http:loki:3100/proxy/loki/api/v1/query_range?query=$(uri "$1")&start=${start}&limit=50" \
    | jq -c '.data.result'
}
loki_has_data() { [ "$(loki_range "$1" "${2:-30}" | jq 'length')" -gt 0 ]; }

# Grafana needs a session; port-forward on a free local port for the test's lifetime.
grafana_start() {
  local log port i
  log=$(mktemp)
  kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana :80 >"$log" 2>&1 &
  on_exit "kill $!; rm -f $log"
  for i in $(seq 1 40); do
    port=$(grep -o '127.0.0.1:[0-9]*' "$log" | head -1 | cut -d: -f2)
    [ -n "$port" ] && break
    sleep 0.5
  done
  GRAFANA="http://127.0.0.1:${port}"
  GRAFANA_AUTH="admin:$(kubectl -n monitoring get secret kube-prometheus-stack-grafana -o jsonpath='{.data.admin-password}' | base64 -d)"
}
grafana() { curl -sf -u "$GRAFANA_AUTH" "$GRAFANA$1"; }

has_label() { # kind/name namespace|"" key value
  [ "$(kubectl get "$1" ${2:+-n "$2"} -o json | jq -r --arg k "$3" '.metadata.labels[$k] // ""')" = "$4" ]
}
