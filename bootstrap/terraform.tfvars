region = "us-east-1"

# Bucket names must be globally unique. Replace <ACCOUNT_ID> before applying,
# e.g. with: aws sts get-caller-identity --query Account --output text
state_bucket_name = "k8s-platform-tfstate-395675597879"
lock_table_name   = "k8s-platform-terraform-lock"
