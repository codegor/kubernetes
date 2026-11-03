# Module 02 · Task 1 — Cluster, namespaces, kubeconfigs, RBAC

| User | Access |
|---|---|
| `mentor` | RW (`edit`) in `mentor`, `student01`, `student02`, `student03` |
| `student01` | RW (`edit`) in `student01` only |
| `student02` | RW in `student02`; RO (`view`) in `student01` and `default` |
| `student03` | RW (`edit`) in `student03` only |

Only namespaced `RoleBinding`s to the built-in `edit` / `view` ClusterRoles. No `ClusterRoleBinding`,
so nobody is cluster-admin. `edit` has no RBAC rights, so nobody can grant themselves more.

Users authenticate with client certificates signed through the Kubernetes CSR API
(`CN=<user>`), one kubeconfig per user in `out/` (git-ignored, it holds private keys).

## Run

```bash
./create-cluster.sh
kubectl apply -f namespaces.yaml -f rbac.yaml
./make-kubeconfigs.sh
./verify.sh
```

Use a kubeconfig:

```bash
kubectl --kubeconfig out/student02.kubeconfig get pods -n student01
```
