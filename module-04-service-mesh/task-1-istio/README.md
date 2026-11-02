# Module 04 · Task 1 — Istio in sidecar mode

Installed by Argo CD (`module-03-platform/task-1-gitops/apps/templates/istio.yaml`):

| Application | Chart | Namespace |
|---|---|---|
| `istio-base` | `base` (CRDs) | `istio-system` |
| `istiod` | `istiod` + `istiod-values.yaml` | `istio-system` |

Sidecar mode = the default `istiod` install with the sidecar injector webhook (no `ambient`
profile, no ztunnel). The istiod HPA is off: kind has no metrics-server.

## Check

```bash
kubectl -n argocd get applications istio-base istiod
kubectl -n istio-system get pods
kubectl get mutatingwebhookconfiguration istio-sidecar-injector
```
