variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type = string
}

variable "account_id" {
  description = "AWS account ID, used to keep S3 bucket/ECR names globally unique"
  type        = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b"]
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "single_nat_gateway" {
  type = bool
}

variable "cluster_version" {
  type    = string
  default = "1.29"
}

variable "node_group_instance_types" {
  type    = list(string)
  default = ["t3.medium"]
}

variable "node_group_capacity_type" {
  type    = string
  default = "ON_DEMAND"
}

variable "node_group_min_size" {
  type = number
}

variable "node_group_max_size" {
  type = number
}

variable "node_group_desired_size" {
  type = number
}

variable "cluster_enabled_log_types" {
  type    = list(string)
  default = ["api"]
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "ecr_repository_name" {
  type = string
}

variable "frontend_ecr_repository_name" {
  type = string
}

variable "app_s3_bucket_name" {
  description = "Globally unique name for the application S3 bucket"
  type        = string
}

variable "app_s3_force_destroy" {
  type    = bool
  default = true
}

variable "secret_placeholder_name" {
  type = string
}

variable "app_service_account_name" {
  description = "Kubernetes service account name the application pods run as (used for IRSA trust policies)"
  type        = string
  default     = "app"
}

variable "db_name" {
  type    = string
  default = "expenses"
}

variable "db_username" {
  type    = string
  default = "app_admin"
}

variable "rds_instance_class" {
  type = string
}

variable "rds_allocated_storage" {
  type = number
}

variable "rds_max_allocated_storage" {
  description = "Ceiling RDS can auto-grow storage to (RDS storage autoscaling)"
  type        = number
}

variable "rds_multi_az" {
  type = bool
}

variable "rds_backup_retention_days" {
  type = number
}

variable "rds_deletion_protection" {
  type = bool
}

variable "rds_skip_final_snapshot" {
  type = bool
}
