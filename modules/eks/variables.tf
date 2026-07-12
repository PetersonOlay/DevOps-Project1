# Inputs for the EKS cluster + managed node group (see main.tf).
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS control plane"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the cluster into"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the EKS control plane ENIs and managed node groups (private subnets)"
  type        = list(string)
}

variable "cluster_enabled_log_types" {
  description = "Control plane log types to send to CloudWatch"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_days" {
  description = "Retention in days for the EKS control plane CloudWatch log group"
  type        = number
  default     = 30
}

variable "node_group_instance_types" {
  description = "Instance types for the default managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_group_capacity_type" {
  description = "Capacity type for the managed node group (ON_DEMAND or SPOT)"
  type        = string
  default     = "ON_DEMAND"
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

variable "tags" {
  description = "Common tags applied to all EKS resources"
  type        = map(string)
  default     = {}
}
