# Copy these values from the `bootstrap` module's outputs after running
# `terraform apply` there once:
#   terraform -chdir=../../bootstrap output -raw state_bucket_name
#   terraform -chdir=../../bootstrap output -raw lock_table_name
#
# Then run: terraform init -backend-config=backend-prod.hcl

bucket         = "k8s-platform-tfstate-395675597879"
dynamodb_table = "k8s-platform-terraform-lock"
