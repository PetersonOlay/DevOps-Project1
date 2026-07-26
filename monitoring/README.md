# Monitoring (Prometheus + Grafana)

Deployed manually via `helm install` (not Terraform-managed), into a dedicated `monitoring`
namespace, using the `prometheus-community/kube-prometheus-stack` chart (Prometheus Operator +
Prometheus + Alertmanager + node-exporter + kube-state-metrics + Grafana). Grafana gets its own
dedicated ALB (separate from the app's Ingress) so it doesn't need Grafana's sub-path `root_url`
configuration.

Platform metrics (nodes, pods, deployments, all cluster resources) come from the chart's bundled
node-exporter + kube-state-metrics and Grafana's built-in default dashboards — no extra
configuration needed. Application metrics come from `app/expense-tracker-backend`'s `/metrics` endpoint
(added via `prom-client`), scraped through `servicemonitor-expense-tracker-<env>.yaml` and
visualized in the custom `expense-tracker-app-dashboard-configmap.yaml` dashboard (auto-imported by
Grafana's sidecar, which watches for ConfigMaps labeled `grafana_dashboard: "1"`).

CloudWatch is also wired in as a second Grafana datasource (`additionalDataSources` in the values
file), so CloudWatch metrics and log groups (including the EKS control-plane/node-group log groups
from `modules/cloudwatch` and the `amazon-cloudwatch-observability` EKS add-on) can be viewed
alongside Prometheus data in the same Grafana instance.

Each environment (`dev`/`stg`/`prod`) is its own EKS cluster, so this stack is installed once per
cluster, into that cluster's own `monitoring` namespace. `kube-prometheus-stack-values.yaml` holds
the shared chart defaults; `kube-prometheus-stack-values-<env>.yaml` carries the one
environment-specific value (Grafana's CloudWatch IRSA role ARN) — same `values.yaml` +
`values-<env>.yaml` layering as `helm/expense-tracker`. Point `kubectl`/`helm` at the target
cluster's context before running any command below.

## Prerequisite: a working StorageClass

The cluster's only existing StorageClass (`gp2`) uses the legacy in-tree `kubernetes.io/aws-ebs`
provisioner, which doesn't work on this EKS version anymore (only the CSI driver does — already
installed as an EKS add-on). `storageclass-gp3.yaml` creates a working one; it's generic and
doesn't need any per-environment change.

## Prerequisite: IRSA role for the CloudWatch datasource

Unlike the rest of this stack, Grafana's CloudWatch access is Terraform-managed (same pattern as
every other IRSA role in this repo — see `environments/<env>/main.tf`,
`module.irsa_grafana_cloudwatch`), since it's an IAM concern, not a Helm one:

```
cd environments/<env>   # dev, stg, or prod
terraform apply
terraform output -raw irsa_grafana_cloudwatch_role_arn
```

Paste that ARN into `monitoring/kube-prometheus-stack-values-<env>.yaml`'s
`grafana.serviceAccount.annotations["eks.amazonaws.com/role-arn"]` before installing/upgrading —
it must be set on the service account annotation *before* the Grafana pod starts, since IRSA
credential injection happens via a mutating admission webhook at pod creation. dev's overlay
already has its real value filled in; stg's and prod's still carry a `REPLACE_WITH_...`
placeholder since neither environment has been applied yet.

## Install (one time per cluster)

```
ENV=dev   # or stg / prod — must match the cluster kubectl is currently pointed at

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring
kubectl apply -f monitoring/storageclass-gp3.yaml

helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f monitoring/kube-prometheus-stack-values.yaml \
  -f monitoring/kube-prometheus-stack-values-$ENV.yaml

kubectl apply -f monitoring/servicemonitor-expense-tracker-$ENV.yaml
kubectl apply -f monitoring/dashboards/expense-tracker-app-dashboard-configmap.yaml
kubectl apply -f monitoring/dashboards/cloudwatch-infra-dashboard-configmap.yaml
```

The app must already be running the version with a named `http` Service port and a `/metrics`
endpoint (`helm/expense-tracker` + `app/expense-tracker-backend` changes deployed via the normal CI
pipeline) for the ServiceMonitor to find anything.

`cloudwatch-infra-dashboard-configmap.yaml` queries the CloudWatch datasource instead of
Prometheus, and has two dropdown variables instead of a fixed target: **RDS Instance**
(`DBInstanceIdentifier`, populated from whatever RDS instances CloudWatch sees in this
account/region) and **Load Balancer** (`LoadBalancer`, populated the same way). Neither the app's
ALB nor Grafana's own ALB has a pinned name, so both show up in the **Load Balancer** dropdown —
pick the app's one for the request/error-rate panels. Both dropdowns are empty until the
corresponding resource actually exists (e.g. before `dev` is deployed).

## Upgrade

```
ENV=dev   # or stg / prod

helm upgrade kube-prometheus-stack prometheus-community/kube-prometheus-stack \
  -n monitoring \
  -f monitoring/kube-prometheus-stack-values.yaml \
  -f monitoring/kube-prometheus-stack-values-$ENV.yaml
```

## Access Grafana

```
# Admin password (auto-generated by the chart, not stored in this repo):
kubectl get secret -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath="{.data.admin-password}" | base64 -d

# URL:
kubectl get ingress -n monitoring
```

Username is `admin`. Once logged in, Connections → Data sources → CloudWatch → "Save & test" should
report both the metrics and logs API queries succeeding — if it fails, check the Grafana pod's
service account annotation and IRSA role trust condition
(`system:serviceaccount:monitoring:kube-prometheus-stack-grafana`).

## Access Prometheus (no Ingress — port-forward)

```
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

Then open `http://localhost:9090` → Status → Targets to confirm the `expense-tracker` target is
`UP`.

## Uninstall

```
helm uninstall kube-prometheus-stack -n monitoring
kubectl delete namespace monitoring
```

Note: PVCs are not deleted by `helm uninstall` by default — delete them manually
(`kubectl get pvc -n monitoring`) if you also want the underlying EBS volumes gone.
