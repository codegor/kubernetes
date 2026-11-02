# Kubernetes course homework

One folder per module, one sub-folder per task. Each module is a separate branch / Pull Request:

| Branch | Module |
|---|---|
| `module-02-security` | Security & Policy as Code |
| `module-03-platform` | Platform Engineering (GitOps + Helm) |
| `module-04-service-mesh` | Service Mesh (Istio) |
| `module-05-observability` | Observability & Troubleshooting |

Branches are stacked: every module branch starts from the previous one.

## Tools

`docker`, `kind`, `kubectl`, `helm`, `openssl`.

## Order

1. `module-02-security/task-1-rbac/create-cluster.sh` — kind cluster (1 control plane + 2 workers).
2. Module 02 tasks — plain manifests applied by hand.
3. Module 03 — Argo CD takes over everything; later modules only add Argo CD Applications.
4. Module 04, Module 05 — merged into the GitOps repo, Argo CD syncs them.

Every task folder has its own `README.md` with the commands and the check.
