# Module 04 · Task 2 — Kyverno: Istio sidecar for `person: student` pods

| File | What |
|---|---|
| `policy.yaml` | `ClusterPolicy` `student-istio-sidecar`: every Pod with `person: student` gets label `sidecar.istio.io/inject: "true"` |
| `injector-after-kyverno.yaml` | Extra webhook that sends those pods to istiod `/inject` |

Why the extra webhook: mutating webhooks run in configuration-name order. Istio's
`istio-sidecar-injector` runs before Kyverno's `kyverno-resource-mutating-webhook-cfg`, so it
never sees the label Kyverno adds. `reinvocationPolicy: IfNeeded` does not help: the API server
re-invokes only webhooks that already ran, and re-checks their selectors.
`zz-istio-sidecar-injector-after-kyverno` sorts after Kyverno and calls the same istiod
endpoint. istiod writes its `caBundle` itself.

Kyverno does not order policies, so `student-istio-sidecar` may run before `add-person-label`
and see no `person` label yet. It therefore also matches pods in namespaces labelled
`person: student` (set by the course-policies chart); those pods always end up with
`person: student`. Without this, about 1 pod in 8 got no sidecar.

Chain at pod creation:

1. Kyverno `add-person-label` → `person: student` (student namespaces).
2. Kyverno `student-istio-sidecar` → `sidecar.istio.io/inject: "true"`.
3. `zz-istio-sidecar-injector-after-kyverno` → istiod adds `istio-init` + `istio-proxy`.

Deployed by Argo CD (Application `student-istio-sidecar`).

## Check

```bash
kubectl apply -f test-deployment.yaml
kubectl -n student03 get pods -l app=mesh-test -o jsonpath='{.items[*].spec.containers[*].name}'
# app istio-proxy
kubectl -n default create deployment mesh-test --image=nginxinc/nginx-unprivileged:1.27-alpine
kubectl -n default get pods -l app=mesh-test -o jsonpath='{.items[*].spec.containers[*].name}'
# nginx-unprivileged   (no sidecar outside student namespaces)
```

Note: the injected `istio-init` container is not read-only, so student pods show up in the
read-only root filesystem audit (Module 02, Audit only).
