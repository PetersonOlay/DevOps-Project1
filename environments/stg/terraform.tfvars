region      = "us-east-1"
environment = "stg"

# Replace with: aws sts get-caller-identity --query Account --output text
account_id = "395675597879"

azs = ["us-east-1a", "us-east-1b"]

vpc_cidr             = "10.1.0.0/16"
private_subnet_cidrs = ["10.1.0.0/19", "10.1.32.0/19"]
public_subnet_cidrs  = ["10.1.64.0/19", "10.1.96.0/19"]
single_nat_gateway   = true

cluster_version = "1.36"

node_group_instance_types = ["t3.medium"]
node_group_capacity_type  = "ON_DEMAND"
node_group_min_size       = 2
node_group_max_size       = 4
node_group_desired_size   = 2

cluster_enabled_log_types = ["api", "audit"]
log_retention_days        = 14

ecr_repository_name = "k8s-platform-app-stg"

app_s3_bucket_name   = "k8s-platform-app-stg-395675597879"
app_s3_force_destroy = true

secret_placeholder_name = "stg/app/placeholder"

app_service_account_name = "app"

db_name     = "expenses"
db_username = "app_admin"

rds_instance_class        = "db.t3.small"
rds_allocated_storage     = 20
rds_multi_az              = false
rds_backup_retention_days = 3
rds_deletion_protection   = false
rds_skip_final_snapshot   = true
