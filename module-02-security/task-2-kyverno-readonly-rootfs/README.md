# Module 02 · Task 2 — Kyverno: read-only root filesystem (Audit)

`policy.yaml` — `ClusterPolicy` `require-readonly-root-filesystem`. Every container, init container
and ephemeral container must have `securityContext.readOnlyRootFilesystem: true`.
`failureAction: Audit` — pods are admitted, violations go to PolicyReports and Events.
Kyverno auto-generates the same rule for Deployments, StatefulSets, Jobs, etc.

## Run

```bash
./install-kyverno.sh
kubectl apply -f policy.yaml
kubectl apply -f test-pods.yaml          # both pods are created (audit, not enforce)
```

## Check

```bash
kubectl get policyreport -n student01
kubectl get events -n student01 --field-selector reason=PolicyViolation
```

`rootfs-bad` has result `fail`, `rootfs-good` has `pass`.
