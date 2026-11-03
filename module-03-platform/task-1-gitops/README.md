# Module 03 · Task 1 — GitOps with Argo CD

Argo CD is installed once with Helm; after that the cluster follows this repository
("app of apps"):

```
root (root-app.yaml)  ->  apps/ (Helm chart of Applications)
                            ├── kyverno          Kyverno Helm chart
                            └── course-policies  ../task-2-helm-policies/course-policies
```

Later modules only add a template to `apps/templates/` — no `kubectl apply` by hand.
All apps sync automatically with `prune` and `selfHeal`.

## Run

The repository must be reachable by the cluster (push it to GitHub first).

```bash
REPO_URL=https://github.com/<you>/<repo>.git ./install-argocd.sh
kubectl -n argocd get applications
```

If Module 02 was applied by hand before, Argo CD adopts the same objects; the manual
`helm install kyverno` can be removed with `helm uninstall kyverno -n kyverno` first.

## Check

```bash
kubectl -n argocd get applications      # all Synced / Healthy
kubectl get clusterpolicy               # require-readonly-root-filesystem, add-person-label
```
