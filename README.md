# expense-tracker on AWS EKS

A small expense & receipt tracking platform running on Amazon EKS, built to demonstrate a complete
Terraform → Kubernetes → CI/CD → observability workflow rather than to be a big application:

- **Infrastructure:** multi-AZ Amazon EKS 1.36 clusters (one per environment) provisioned by
  Terraform, with a dedicated VPC, managed node group, and IRSA for every AWS-facing workload
- **Backend:** Node.js + Express REST API, storing records in RDS Postgres and receipt files in S3
- **Frontend:** React 18 + Vite single-page app, served by nginx, sharing one ALB with the backend
- **Data:** PostgreSQL on RDS (AWS-managed master password, never seen by Terraform), a
  KMS-free S3 bucket for receipts, two ECR repositories (backend/frontend)
- **Deployment:** a single Helm chart (`helm/expense-tracker`) for both services
- **CI/CD:** GitHub Actions — builds and pushes both images, bumps their tags, and runs
  `helm upgrade` on every push to `main`
- **Observability:** Prometheus + Grafana (`kube-prometheus-stack`) for platform and application
  metrics, plus CloudWatch as a second Grafana datasource

---

## Platform Overview

### Infrastructure

- **Amazon EKS 1.36** — managed control plane, `authentication_mode = API_AND_CONFIG_MAP` (both
  the aws-auth ConfigMap and the newer EKS Access Entries API work)
- **VPC** — 2 AZs, public + private subnets, NAT gateway (single for dev/stg, one per AZ for prod)
- **EKS Managed Node Group** — Amazon Linux, capacity type and sizing vary per environment
- **EKS-managed add-ons** — `vpc-cni`, `coredns`, `kube-proxy`, `aws-ebs-csi-driver`,
  `metrics-server`, `amazon-cloudwatch-observability` (`modules/eks-addons`)
- **AWS Load Balancer Controller + Cluster Autoscaler** — Helm releases applied by Terraform
  (`environments/<env>/helm.tf`)
- **IRSA everywhere** — one scoped IAM role per workload (VPC CNI, EBS CSI, Cluster Autoscaler,
  Load Balancer Controller, the app, CloudWatch Observability, Grafana's CloudWatch datasource);
  see `modules/irsa`
- **S3 + DynamoDB-free state backend** — `bootstrap/` is a one-time, local-state root module that
  creates the S3 bucket used as the backend for every environment

### Application

- **`app/expense-tracker`** — the API (Deployment + Service in the Helm chart)
- **`app/expense-tracker-frontend`** — the UI (its own Deployment + Service)
- **RDS PostgreSQL** — private, one instance per environment, master password AWS-managed
  (`modules/rds`)
- **S3 app bucket** — versioned, encrypted, TLS-only bucket policy, holds uploaded receipts
  (`modules/s3-app-bucket`)
- **Secrets Manager** — a placeholder secret per environment for miscellaneous app config
  (`modules/secrets-manager`); the RDS password lives in its own AWS-managed secret, not this one
- **2 ECR repositories per environment** — `k8s-platform-app-<env>` (backend),
  `k8s-platform-frontend-<env>` (frontend) (`modules/ecr`)
- **Helm chart** — `helm/expense-tracker`, one release for both services
- **CI/CD** — `.github/workflows/build-and-deploy.yml`
- **Monitoring** — `monitoring/` (Prometheus + Grafana + CloudWatch datasource)

---

## Architecture

### Network

- VPC per environment, `10.0.0.0/16` (dev) / `10.1.0.0/16` (stg) / `10.2.0.0/16` (prod), 2 AZs,
  public + private `/19` subnets (`modules/vpc`).
- NAT strategy: dev/stg share a single NAT gateway; prod runs one per AZ so a zone outage doesn't
  cut off all outbound traffic.
- **Ingress**: the app is reachable through one ALB per environment, provisioned by the AWS Load
  Balancer Controller from `helm/expense-tracker/templates/ingress.yaml`. Paths are split so both
  services share the same origin (no CORS needed): `/expenses*` and `/healthz` route to the
  backend Service, everything else (`/`) routes to the frontend Service.

### Compute

- One EKS managed node group per environment, spanning both private subnets (`modules/eks`).
- **Namespaces**: `expense-tracker-<env>` runs the app (backend + frontend + migration Job);
  `kube-system` runs cluster add-ons; `monitoring` runs Prometheus/Grafana.
- The app's namespace is created by Terraform (`kubernetes_namespace.app`), not by Helm — see
  [Security](#security) for why.

### Data layer

- **RDS PostgreSQL** — `gp3`-backed, sizing/Multi-AZ varies per environment, security group scoped
  to the EKS node security group only (`modules/rds`).
- **S3 app bucket** — receipts stored under `<env>/receipts/`.
- **Secrets Manager** — one placeholder secret per environment; Terraform never writes to it after
  creation (`lifecycle { ignore_changes = [secret_string] }`), so the app team can populate real
  values without Terraform reverting them.
- **ECR** — two repositories per environment (see above), IMMUTABLE tags, scan-on-push, lifecycle
  policy expiring old untagged/excess-tagged images.

### Terraform layout

- **`bootstrap/`** — one-time, local-state module creating the S3 state bucket. Applied manually,
  once per AWS account, before anything else.
- **`modules/`** — reusable building blocks: `vpc`, `eks`, `eks-addons`, `irsa`, `ecr`, `rds`,
  `s3-app-bucket`, `secrets-manager`, `cloudwatch`, `ci-deployer`. `vpc` and `eks` wrap the
  `terraform-aws-modules/vpc/aws` and `terraform-aws-modules/eks/aws` registry modules.
- **`environments/{dev,stg,prod}/`** — one root module per environment; identical files, different
  `terraform.tfvars` (CIDR, NAT strategy, node/RDS sizing, log retention).

---

## Backend (app/expense-tracker)

Node.js + Express, using `pg` for Postgres and the AWS SDK v3 for S3/Secrets Manager.

| Method | Path | Purpose |
|---|---|---|
| `POST` | `/expenses` | Create an expense (multipart form, optional receipt upload) |
| `GET` | `/expenses` | List expenses (filter by `category`/`month`) |
| `GET` | `/expenses/:id` | Get one expense, with a presigned receipt URL if uploaded |
| `PUT` | `/expenses/:id` | Update an expense, optionally replacing the receipt |
| `DELETE` | `/expenses/:id` | Delete an expense and its receipt object |
| `GET` | `/expenses/summary` | Totals grouped by category and month |
| `GET` | `/healthz` | Liveness/readiness probe target |
| `GET` | `/metrics` | Prometheus exposition format (`prom-client`) |

On boot, the app fetches its DB credentials from the RDS-managed Secrets Manager secret using its
pod's IRSA role — no database password ever touches Terraform state or a Kubernetes Secret.
Schema migrations (`src/migrate.js`) run as a Helm `post-install,post-upgrade` hook.

## Frontend (app/expense-tracker-frontend)

React 18 + Vite, built to a static bundle and served by nginx. Talks to the API with **same-origin
relative fetches** (`fetch("/expenses")`) — no API base URL or CORS configuration needed, since
both services sit behind the same ALB. Supports creating, editing, deleting, and summarizing
expenses, with receipt upload/replace.

## Helm chart (helm/expense-tracker)

One chart, one release per environment, both services:

- `serviceaccount.yaml` — annotated with the app's IRSA role ARN
- `configmap.yaml` — non-secret config (DB host/port, S3 bucket, region)
- `deployment.yaml` / `service.yaml` — backend
- `frontend-deployment.yaml` / `frontend-service.yaml` — frontend
- `ingress.yaml` — one ALB, path-split between the two Services
- `migration-job.yaml` — a `post-install,post-upgrade` hook (Job specs are immutable, so a plain
  `helm upgrade` can't patch one in place once the image tag changes — the hook deletes the
  previous Job and creates a fresh one instead)

`values.yaml` holds chart defaults; `values-<env>.yaml` carries environment-specific values
(image repository/tag, replica count, IRSA role ARN, RDS endpoint, S3 bucket). See
[`helm/expense-tracker/README.md`](helm/expense-tracker/README.md) for install/upgrade commands.

---

## Project Structure

```
DevOps-Projects/
├── bootstrap/                       # One-time: S3 state bucket (local state)
├── modules/
│   ├── vpc/                         # Wraps terraform-aws-modules/vpc/aws
│   ├── eks/                         # Wraps terraform-aws-modules/eks/aws
│   ├── eks-addons/                  # vpc-cni, coredns, kube-proxy, ebs-csi, metrics-server, cloudwatch-observability
│   ├── irsa/                        # Generic IRSA role wrapper
│   ├── ecr/                         # ECR repository + lifecycle policy
│   ├── rds/                         # RDS Postgres instance + security group
│   ├── s3-app-bucket/               # App receipts bucket
│   ├── secrets-manager/             # Placeholder secret
│   ├── cloudwatch/                  # Log groups
│   └── ci-deployer/                 # Per-environment CI IAM user (scoped ECR push + EKS access)
├── environments/
│   ├── dev/  stg/  prod/            # One root module per environment
├── app/
│   ├── expense-tracker/             # Backend (Node.js + Express)
│   └── expense-tracker-frontend/    # Frontend (React + Vite)
├── helm/
│   └── expense-tracker/             # Helm chart for both services
├── .github/
│   └── workflows/
│       └── build-and-deploy.yml     # CI/CD pipeline
└── monitoring/                      # Prometheus + Grafana (manually helm-installed)
```

---

## Prerequisites

| Tool | Notes |
|---|---|
| Terraform | >= 1.5 |
| AWS CLI | configured with credentials that can create VPC/EKS/IAM/RDS/S3/ECR/Secrets Manager/CloudWatch resources |
| kubectl | any recent version |
| Helm | >= 3 |
| Docker | for local image builds |
| Node.js | 20+ (matches the app's runtime and CI) |
| Git | GPG signing configured if you want verified commits |

## Setup & Deployment

### 1. Bootstrap remote state (once per AWS account)

```bash
cd bootstrap
# edit terraform.tfvars: replace <ACCOUNT_ID> in state_bucket_name
terraform init
terraform apply
```

Keep `bootstrap/terraform.tfstate` safe — it describes the state bucket itself, so it isn't stored
remotely.

### 2. Apply an environment

```bash
cd environments/dev
# edit terraform.tfvars and backend-dev.hcl: replace <ACCOUNT_ID>
terraform init -backend-config=backend-dev.hcl
terraform plan
terraform apply
```

This creates the VPC, EKS cluster, RDS instance, ECR repos, S3 bucket, IRSA roles, EKS add-ons,
the `ci_deployer` CI user, and the app's Kubernetes namespace.

### 3. Wire up CI/CD

Create a matching GitHub Environment (`dev`/`stg`/`prod`) and set its secrets/variables from the
`environments/<env>` Terraform outputs. See
[`.github/workflows/README.md`](.github/workflows/README.md) for the exact list and commands.

### 4. Fill in the Helm values

`helm/expense-tracker/values-<env>.yaml` needs the real `image.repository`,
`frontend.image.repository`, `serviceAccount.roleArn`, `config.dbHost`, `config.dbSecretArn`, and
`config.s3Bucket` from the same Terraform outputs — the pipeline only ever bumps image tags, not
these. See [`helm/expense-tracker/README.md`](helm/expense-tracker/README.md).

### 5. First deploy

Push to `main` (or trigger `workflow_dispatch` targeting the environment) — CI builds and pushes
both images, then runs `helm upgrade --install`.

```bash
aws eks update-kubeconfig --name k8s-platform-dev --region us-east-1
kubectl get pods -n expense-tracker-dev
kubectl get ingress -n expense-tracker-dev
```

### 6. Install monitoring (optional, per cluster)

```bash
cd monitoring
# see monitoring/README.md for the full sequence
```

---

## CI/CD Pipeline

`.github/workflows/build-and-deploy.yml`, three jobs:

1. **test** — `npm ci && npm test` in `app/expense-tracker`.
2. **build-and-push** — builds and pushes both images to their ECR repos, tagged
   `app-<env>-<timestamp>` (backend) / `web-<env>-<timestamp>` (frontend).
3. **deploy** — bumps both tags in `values-<env>.yaml` with `yq`, commits the change back to
   `main`, then runs `helm upgrade --install` against the target cluster.

Triggers: push to `main` deploys to `dev` automatically; `workflow_dispatch` lets you pick
`dev`/`stg`/`prod` manually. Each environment authenticates with its own scoped, Terraform-managed
IAM user (`modules/ci-deployer`) via GitHub Environment secrets — no shared or long-lived
cross-environment credentials.

## Monitoring

Prometheus + Grafana (`kube-prometheus-stack`, manually `helm install`ed — see
[`monitoring/README.md`](monitoring/README.md)) cover both platform metrics (nodes, pods,
deployments — built-in dashboards) and application metrics (`app/expense-tracker`'s `/metrics`
endpoint, scraped via a `ServiceMonitor`, visualized in a custom dashboard). Grafana also has
CloudWatch wired in as a second datasource (its own IRSA role, `module.irsa_grafana_cloudwatch`),
so CloudWatch log groups and metrics are viewable in the same place.

---

## Environments

| | dev | stg | prod |
|---|---|---|---|
| NAT gateway | single | single | one per AZ |
| Node capacity type | SPOT | ON_DEMAND | ON_DEMAND |
| Node group size (min/max/desired) | 1/3/2 | 2/4/2 | 3/10/4 |
| RDS instance class | `db.t3.micro` | `db.t3.small` | `db.r6g.large` |
| RDS Multi-AZ | no | no | yes |
| RDS deletion protection | no | no | yes |
| Log retention | 7 days | 14 days | 90 days |
| Frontend/backend replicas | 1 | 2 | 3 |

Only `dev` has been deployed and verified end-to-end so far; `stg`/`prod` are defined but not yet
applied.

## Security

- **IRSA everywhere** — every AWS-facing workload (VPC CNI, EBS CSI, Cluster Autoscaler, Load
  Balancer Controller, the app, CloudWatch Observability, Grafana) assumes a scoped IAM role via
  its Kubernetes service account. No pod carries static AWS credentials.
- **Least-privilege CI identity** — `modules/ci-deployer` creates one IAM user per environment,
  scoped to that environment's two ECR repos and a namespace-scoped EKS Access Entry
  (`AmazonEKSEditPolicy` restricted to `expense-tracker-<env>` only — it cannot create namespaces
  or touch cluster-scoped resources).
- **RDS password never touches Terraform** — `manage_master_user_password = true` lets AWS create
  and rotate it directly in Secrets Manager.
- **TLS-only S3 bucket policies** on both the state bucket and the app bucket.
- **GPG-signed commits** on this repo.

---

## Troubleshooting

Real issues hit (and fixed) while building this out:

**`Error: Unsupported argument: most_recent`** — `aws_eks_addon` doesn't have a `most_recent`
argument in this AWS provider version; omit `addon_version` entirely to get the default version.

**`Invalid for_each argument` on the RDS security group rule** — `for_each` needs its *keys* known
at plan time; `module.eks.node_security_group_id` isn't known until the cluster exists. Switched
to `count = length(var.allowed_security_group_ids)`, which only needs the list *length* known.

**vpc-cni pods crash-looping with `Unauthorized operation: ec2:DescribeNetworkInterfaces`** — the
`iam-role-for-service-accounts-eks` submodule needs `vpc_cni_enable_ipv4 = true` or it generates an
almost-empty CNI policy (just `ec2:CreateTags`).

**Cluster Autoscaler IRSA policy error** — the submodule's `attach_cluster_autoscaler_policy` also
needs `cluster_autoscaler_cluster_names` set, or policy generation fails with a `coalescelist`
error.

**`helm install --create-namespace` → `namespaces is forbidden`** — the CI deployer's EKS access is
deliberately scoped to one namespace; creating a Namespace is a cluster-scoped operation it can't
do. Fix: the app namespace is created by Terraform (the cluster-admin principal) instead, and
`--create-namespace` is never passed by the pipeline.

**`helm upgrade` failing on the migration Job: `Invalid value: ... spec.template`** —
`Job.spec.template` is immutable, and the image tag changes every deploy. Fixed by making the Job
a `post-install,post-upgrade` Helm hook (`hook-delete-policy: before-hook-creation`), so Helm
deletes the old Job and creates a new one instead of patching in place.

**App unreachable through the ALB despite `Running` pods** — the ALB target group's health check
defaults to path `/`, expecting `200`; the backend has no root route (`404`), so the target was
marked unhealthy. Fixed with an explicit `alb.ingress.kubernetes.io/healthcheck-path: /healthz`
annotation — and hit the same trap again for the frontend Service once it was added (its target
group inherited the same shared annotation), fixed by adding a `/healthz` stub to its nginx config.

**Prometheus/Grafana PVCs stuck `Pending`** — the cluster's only `StorageClass` (`gp2`) used the
legacy in-tree `kubernetes.io/aws-ebs` provisioner, which no longer works on this EKS version
(only the CSI driver does). Fixed by creating a CSI-backed `gp3` StorageClass.

**`kubectl annotate ... /healthz` silently became `.../C:/Program Files/Git/healthz`** — Git Bash
on Windows auto-converts arguments that look like POSIX paths. Fixed with `MSYS_NO_PATHCONV=1`.

---

## Teardown

```bash
# Monitoring
helm uninstall kube-prometheus-stack -n monitoring
kubectl delete namespace monitoring

# App
helm uninstall expense-tracker -n expense-tracker-dev

# Infrastructure (per environment, then bootstrap last)
cd environments/dev && terraform destroy
cd ../../bootstrap && terraform destroy
```

PVCs (and their underlying EBS volumes) aren't deleted automatically by `helm uninstall` — check
`kubectl get pvc -A` and delete them manually first if you want a clean teardown.
