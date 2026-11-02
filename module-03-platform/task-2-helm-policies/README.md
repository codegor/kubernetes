# Module 03 · Task 2 — Module 02 as a Helm chart

`course-policies/` renders everything from Module 02 out of `values.yaml`:

| Template | Content |
|---|---|
| `namespaces.yaml` | `mentor` + one namespace per student |
| `rbac.yaml` | mentor `edit` in own + every student namespace; student `edit` in own namespace; `readOnlyNamespaces` → `view` |
| `kyverno-readonly-rootfs.yaml` | `require-readonly-root-filesystem`, `failureAction` from values (`Audit`) |
| `kyverno-person-label.yaml` | `add-person-label`, namespace lists built from `students` / `mentor` |

Adding a student = one entry in `students`; RBAC and the label policy follow.

The kubeconfigs stay a script (`module-02-security/task-1-rbac/make-kubeconfigs.sh`): they hold
private keys and do not belong in Git.

Argo CD installs this chart (Application `course-policies`, see `../task-1-gitops`).

## Check locally

```bash
helm lint course-policies
helm template course-policies course-policies | less
```
