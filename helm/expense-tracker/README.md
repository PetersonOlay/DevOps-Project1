# expense-tracker Helm chart

Deploys the expense-tracker API (Deployment, Service, ALB Ingress, ServiceAccount with IRSA
annotation, ConfigMap, one-shot DB migration Job) to the EKS cluster provisioned by the Terraform
project in this repo.

## Values

`values.yaml` holds chart defaults. `values-<env>.yaml` carries the environment-specific bits that
come from Terraform outputs, image tag, and replica count. Fill in every `REPLACE_WITH_*`
placeholder in `values-<env>.yaml` before installing:

```
terraform -chdir=../../environments/dev output
```

maps to `image.repository` (`ecr_repository_url`), `serviceAccount.roleArn` (`irsa_app_role_arn`),
`config.dbHost` (`rds_endpoint`), `config.dbSecretArn` (`rds_master_user_secret_arn`), and
`config.s3Bucket` (`app_s3_bucket_name`).

## Install

```
helm lint expense-tracker
helm template expense-tracker -f values.yaml -f values-dev.yaml   # review rendered manifests
helm install expense-tracker . -n default --create-namespace -f values.yaml -f values-dev.yaml
```

## Upgrade

```
helm upgrade expense-tracker . -n default -f values.yaml -f values-dev.yaml
```

The migration Job (`expense-tracker-migrate`) has a fixed name and immutable spec — if you change
the schema and need it to re-run on upgrade, delete it first:

```
kubectl delete job expense-tracker-migrate -n default
helm upgrade expense-tracker . -n default -f values.yaml -f values-dev.yaml
```

## Uninstall

```
helm uninstall expense-tracker -n default
```
