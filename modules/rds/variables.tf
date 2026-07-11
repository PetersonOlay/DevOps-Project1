variable "identifier" {
  description = "RDS instance identifier"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for the DB subnet group"
  type        = list(string)
}

variable "allowed_security_group_ids" {
  description = "Security groups allowed to reach the database on the Postgres port (e.g. the EKS node security group)"
  type        = list(string)
}

variable "engine_version" {
  type    = string
  default = "18.4"
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "db_name" {
  type = string
}

variable "username" {
  type = string
}

variable "port" {
  type    = number
  default = 5432
}

variable "multi_az" {
  type = bool
}

variable "backup_retention_period" {
  type = number
}

variable "deletion_protection" {
  type = bool
}

variable "skip_final_snapshot" {
  type = bool
}

variable "tags" {
  type    = map(string)
  default = {}
}
