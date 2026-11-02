# Module 05 · Task 2 — Dashboard: node load by student namespace

`dashboard-configmap.yaml` → Grafana dashboard **Student namespaces — node load**
(uid `student-node-load`). Variables: `namespace` (all `student*`), `node`.

| Panel | Query basis |
|---|---|
| CPU cores by node / namespace | cAdvisor `container_cpu_usage_seconds_total` joined with `kube_pod_info` for the node |
| CPU % of node allocatable | same ÷ `kube_node_status_allocatable{resource="cpu"}` |
| Memory by node / namespace | `container_memory_working_set_bytes` + `kube_pod_info` |
| Memory % of node allocatable | same ÷ `kube_node_status_allocatable{resource="memory"}` |
| Requests vs usage table | `kube_pod_container_resource_requests`, pod count |
| Pods per node / namespace | `kube_pod_info` |

## Load to test

```bash
for ns in student01 student02 student03; do
  kubectl -n $ns create deployment burn --image=busybox:1.36 --replicas=2 -- sh -c 'while :; do :; done'
done
```
