# CI/CD setup (manual, one-time)

`build-and-deploy.yml` builds and pushes `app/expense-tracker`, bumps the image tag in
`helm/expense-tracker/values-<env>.yaml`, and runs `helm upgrade --install` against the target
EKS cluster. It authenticates to AWS via a **static access-key IAM user, scoped per environment**
(no OIDC).

## 1. Create each environment's CI deployer user

For each of `dev`, `stg`, `prod`:

```
cd environments/<env>
terraform apply
terraform output -raw ci_deployer_access_key_id
terraform output -raw ci_deployer_secret_access_key
terraform output -raw ecr_repository_url
```

`ci_deployer_secret_access_key` is only ever printed to your terminal — never commit it, and paste
it straight into the matching GitHub Environment secret in the next step.

This same `terraform apply` also creates the app's Kubernetes namespace
(`kubernetes_namespace.app`, named `expense-tracker-<env>` — see the `app_namespace` output). It's
created by the Terraform-applying principal (cluster-admin), not the CI deployer user — that
user's EKS access is deliberately scoped to just that one namespace and can't create namespaces
itself (a cluster-scoped operation), so don't pass `--create-namespace` to `helm`.

## 2. Create the matching GitHub Environments

In the repo: Settings → Environments → New environment, one each named exactly `dev`, `stg`,
`prod` (the workflow's `environment:` key must match). For each:

**Secrets:**

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | that environment's `ci_deployer_access_key_id` output |
| `AWS_SECRET_ACCESS_KEY` | that environment's `ci_deployer_secret_access_key` output |

**Variables:**

| Variable | Value |
|---|---|
| `AWS_REGION` | `us-east-1` |
| `ECR_REGISTRY` | that environment's `ecr_repository_url` output |
| `EKS_CLUSTER` | `k8s-platform-<env>` |
| `NAMESPACE` | that environment's `app_namespace` output (`expense-tracker-<env>`) |

Consider adding required-reviewer protection rules on the `stg`/`prod` GitHub Environments to gate
who can trigger a deployment to them.

## 3. Fill in the Helm values placeholders

The pipeline only ever bumps `image.tag`. Everything else in
`helm/expense-tracker/values-<env>.yaml` (`image.repository`, `serviceAccount.roleArn`,
`config.dbHost`, `config.dbSecretArn`, `config.s3Bucket`) must be filled in once from that
environment's `terraform output` before the first deploy — see
`helm/expense-tracker/README.md`.

## Triggering

- Push to `main` → deploys to `dev` automatically.
- Actions tab → "Build and Deploy" → "Run workflow" → pick `dev`/`stg`/`prod` to deploy manually
  to any environment.

## Rotating the CI deployer credentials

The access key is Terraform-managed (`aws_iam_access_key` in `modules/ci-deployer`). To rotate it,
taint and re-apply that resource for the affected environment, then update the GitHub Environment
secret with the new value:

```
terraform taint module.ci_deployer.aws_iam_access_key.this
terraform apply
```
