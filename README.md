# k8s-platform — Terraform EKS

Multi-AZ EKS clusters in `us-east-1`, one per environment (`dev`, `stg`, `prod`), each with its
own VPC, managed node group, ECR repo, app S3 bucket, Secrets Manager placeholder, CloudWatch log
groups, and AWS Load Balancer Controller / Cluster Autoscaler.

## Layout

- `bootstrap/` — one-time, local-state module that creates the S3 bucket + DynamoDB table used
  as the remote backend for everything else.
- `modules/` — reusable building blocks (`vpc`, `eks`, `irsa`, `eks-addons`, `ecr`,
  `s3-app-bucket`, `secrets-manager`, `cloudwatch`). `vpc` and `eks` are thin wrappers around the
  `terraform-aws-modules/vpc/aws` and `terraform-aws-modules/eks/aws` registry modules.
- `environments/{dev,stg,prod}/` — one root module per environment, same files, different
  `terraform.tfvars`.

## Prerequisites

- Terraform >= 1.5, AWS CLI configured with credentials that can create VPC/EKS/IAM/S3/ECR/
  Secrets Manager/CloudWatch resources.
- `kubectl` and `helm` (only needed after the cluster exists, for verification).
- Your AWS account ID: `aws sts get-caller-identity --query Account --output text`.

## 1. Bootstrap remote state (once per AWS account)

```
cd bootstrap
# edit terraform.tfvars: replace <ACCOUNT_ID> in state_bucket_name
terraform init
terraform apply
terraform output
```

Keep `bootstrap/terraform.tfstate` safe — it's the only state describing the state bucket itself
(not stored remotely, since it creates the remote backend).

## 2. Deploy an environment

For each of `dev`, `stg`, `prod`:

```
cd environments/dev
# edit terraform.tfvars and backend-dev.hcl: replace <ACCOUNT_ID>
terraform init -backend-config=backend-dev.hcl
terraform validate
terraform plan
terraform apply
```

`terraform.tfvars` differentiates environments: VPC CIDR, NAT gateway strategy (single for
dev/stg, one per AZ for prod), node group sizing/capacity type, CloudWatch log retention, and
control-plane log types.

## 3. Verify

```
aws eks update-kubeconfig --name k8s-platform-dev --region us-east-1
kubectl get nodes
kubectl get pods -n kube-system   # vpc-cni, coredns, kube-proxy, ebs-csi, lb-controller, cluster-autoscaler
```

Create a test `Ingress`/`Service type=LoadBalancer` and confirm the AWS Load Balancer Controller
provisions an ALB (`kubectl get ingress`).

To verify IRSA, exec into a pod running as the `app` service account (in the namespace set by
`app_namespace`/`app_service_account_name`) and confirm it can call
`aws secretsmanager get-secret-value` and `aws s3 ls` on the environment's secret/bucket using its
assumed pod role, not the node's instance role.

## Notes

- Cluster auth uses `authentication_mode = API_AND_CONFIG_MAP` — both the aws-auth ConfigMap and
  the EKS Access Entries API work. The Terraform-applying principal gets an admin access entry
  automatically (`enable_cluster_creator_admin_permissions = true`).
- Secrets Manager and the app S3 bucket are provisioned empty/placeholder — Terraform never owns
  secret *values*, only the resource and IAM access.
- S3 bucket names (state bucket, app bucket) and the ECR repo/tfstate keys must be globally
  unique — tfvars use an `<ACCOUNT_ID>` placeholder to keep them so.
