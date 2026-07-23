# expense-tracker Helm chart

Deploys both expense-tracker services to the EKS cluster provisioned by the Terraform project in
this repo, as one Helm release:
- **backend** (Deployment, Service, ServiceAccount with IRSA annotation, ConfigMap, one-shot DB
  migration Job) — the JSON API in `app/expense-tracker-backend`.
- **frontend** (Deployment, Service) — the React UI in `app/expense-tracker-frontend`, serving
  static files via nginx.

Both share a single ALB Ingress, split by path: `/expenses` and `/healthz` route to the backend
Service, everything else (`/`) routes to the frontend Service. Same origin for both, so the
frontend's `fetch("/expenses")` calls need no CORS configuration or API base URL.

## Namespace

Each environment gets its own friendly, environment-scoped namespace — `expense-tracker-dev`,
`expense-tracker-stg`, `expense-tracker-prod` — created by Terraform
(`kubernetes_namespace.app` in `environments/<env>/main.tf`, see the `app_namespace` output), not
by Helm. The CI deployer IAM user's EKS access is scoped to only that one namespace
(`AmazonEKSEditPolicy` with a namespace-scoped `access_scope`) and can't create namespaces itself
(a cluster-scoped operation), so never pass `--create-namespace` — the namespace must already
exist before you `helm install`/`upgrade`.

## Values

`values.yaml` holds chart defaults. `values-<env>.yaml` carries the environment-specific bits that
come from Terraform outputs, image tag, and replica count. Fill in every `REPLACE_WITH_*`
placeholder in `values-<env>.yaml` before installing:

```
terraform -chdir=../../environments/dev output
```

maps to `image.repository` (`ecr_repository_url`), `frontend.image.repository`
(`frontend_ecr_repository_url`), `serviceAccount.roleArn` (`irsa_app_role_arn`), `config.dbHost`
(`rds_endpoint`), `config.dbSecretArn` (`rds_master_user_secret_arn`), and `config.s3Bucket`
(`app_s3_bucket_name`).

## Install

```
helm lint expense-tracker
helm template expense-tracker -f values.yaml -f values-dev.yaml   # review rendered manifests
helm install expense-tracker . -n expense-tracker-dev -f values.yaml -f values-dev.yaml
```

## Upgrade

```
helm upgrade expense-tracker . -n expense-tracker-dev -f values.yaml -f values-dev.yaml
```

The migration Job (`expense-tracker-<env>-migrate`, e.g. `expense-tracker-dev-migrate` — resource
names are suffixed with `config.appEnv` so they're identifiable across environments/namespaces at
a glance) runs as a `post-install,post-upgrade` Helm hook with
`hook-delete-policy: before-hook-creation` — Helm deletes the previous Job and creates a fresh one
on every install/upgrade automatically (Job specs are immutable, so a plain in-place patch would
fail once the image tag changes). No manual cleanup needed between deploys.

## Uninstall

```
helm uninstall expense-tracker -n expense-tracker-dev
```
