region      = "us-east-1"
environment = "prod"

# Replace with: aws sts get-caller-identity --query Account --output text
account_id = "395675597879"

azs = ["us-east-1a", "us-east-1b"]

vpc_cidr             = "10.2.0.0/16"
private_subnet_cidrs = ["10.2.0.0/19", "10.2.32.0/19"]
public_subnet_cidrs  = ["10.2.64.0/19", "10.2.96.0/19"]
single_nat_gateway   = false

cluster_version = "1.36"

node_group_instance_types = ["m5.large"]
node_group_capacity_type  = "ON_DEMAND"
node_group_min_size       = 3
node_group_max_size       = 10
node_group_desired_size   = 4

cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
log_retention_days        = 90

backend_ecr_repository_name  = "expense-platform-backend-prod"
frontend_ecr_repository_name = "expense-platform-frontend-prod"

app_s3_bucket_name   = "expense-platform-app-prod-395675597879"
app_s3_force_destroy = false

secret_placeholder_name = "prod/app/placeholder"

app_service_account_name = "app"

db_name     = "expenses"
db_username = "app_admin"

rds_instance_class        = "db.r6g.large"
rds_allocated_storage     = 100
rds_max_allocated_storage = 500
rds_multi_az              = true
rds_backup_retention_days = 14
rds_deletion_protection   = true
rds_skip_final_snapshot   = false
