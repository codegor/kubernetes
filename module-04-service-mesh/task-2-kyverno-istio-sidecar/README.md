# Module 04 · Task 2 — Kyverno: Istio sidecar for `person: student` pods

`policy.yaml` — `ClusterPolicy` `student-istio-sidecar`: every Pod with label
`person: student` gets label `sidecar.istio.io/inject: "true"`. Istio's
`object.sidecar-injector` webhook selects pods by that label (in namespaces without an
`istio-injection` label) and adds the `istio-proxy` container.

Chain at pod creation:

1. Kyverno `add-person-label` → `person: student` (student namespaces).
2. Kyverno `student-istio-sidecar` → `sidecar.istio.io/inject: "true"`.
3. Istio injector (re-invoked, `reinvocationPolicy: IfNeeded`) → `istio-proxy` sidecar.

Deployed by Argo CD (Application `student-istio-sidecar`).

## Check

```bash
kubectl apply -f test-deployment.yaml
kubectl -n student03 get pods -l app=mesh-test \
  -o jsonpath='{range .items[*]}{.metadata.labels}{"  "}{.spec.containers[*].name}{"\n"}{end}'
# -> person=student, sidecar.istio.io/inject=true; containers: app istio-proxy
```

The same Deployment in `default` gets no sidecar.

Note: the injected `istio-init` container is not read-only, so student pods show up in the
read-only root filesystem audit (Module 02, Audit only).
