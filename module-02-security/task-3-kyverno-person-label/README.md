# Module 02 · Task 3 — Kyverno: `person` label

`policy.yaml` — mutating `ClusterPolicy` `add-person-label`, three rules:

| Namespace | `person` label |
|---|---|
| `student01`, `student02`, `student03` | `student` (forced, user value overwritten) |
| `mentor` | `mentor` (forced) |
| any other | removed |

Kyverno already skips its own namespace and `kube-system` (its `resourceFilters`).

## Run

```bash
kubectl apply -f policy.yaml
kubectl apply -f test-pods.yaml
kubectl get pods -A -l person --show-labels | grep label-test
kubectl get pod label-test -n default --show-labels   # no person label
```
