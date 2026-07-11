variable "region" {
  description = "AWS region for the state bucket and lock table"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "Globally unique name for the Terraform state S3 bucket (e.g. include account ID)"
  type        = string
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table used for Terraform state locking"
  type        = string
  default     = "terraform-state-lock"
}

variable "tags" {
  description = "Common tags applied to bootstrap resources"
  type        = map(string)
  default = {
    Project   = "k8s-platform"
    ManagedBy = "terraform"
    Component = "bootstrap"
  }
}
