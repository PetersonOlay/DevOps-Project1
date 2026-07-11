region      = "us-east-1"
environment = "dev"

# Replace with: aws sts get-caller-identity --query Account --output text
account_id = "395675597879"

azs = ["us-east-1a", "us-east-1b"]

vpc_cidr             = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.0.0/19", "10.0.32.0/19"]
public_subnet_cidrs  = ["10.0.64.0/19", "10.0.96.0/19"]
single_nat_gateway   = true

cluster_version = "1.36"

node_group_instance_types = ["t3.medium"]
node_group_capacity_type  = "SPOT"
node_group_min_size       = 1
node_group_max_size       = 3
node_group_desired_size   = 2

cluster_enabled_log_types = ["api"]
log_retention_days        = 7

ecr_repository_name = "k8s-platform-app-dev"

app_s3_bucket_name   = "k8s-platform-app-dev-395675597879"
app_s3_force_destroy = true

secret_placeholder_name = "dev/app/placeholder"

app_namespace            = "default"
app_service_account_name = "app"

db_name     = "expenses"
db_username = "app_admin"

rds_instance_class        = "db.t3.micro"
rds_allocated_storage     = 20
rds_multi_az              = false
rds_backup_retention_days = 1
rds_deletion_protection   = false
rds_skip_final_snapshot   = true
