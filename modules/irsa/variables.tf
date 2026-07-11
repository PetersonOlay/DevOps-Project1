variable "role_name" {
  description = "Name for the IAM role"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the cluster's OIDC provider (module.eks.oidc_provider_arn)"
  type        = string
}

variable "namespace_service_accounts" {
  description = "List of \"namespace:service_account_name\" strings allowed to assume this role"
  type        = list(string)
}

variable "attach_vpc_cni_policy" {
  type    = bool
  default = false
}

variable "vpc_cni_enable_ipv4" {
  description = "Include the IPv4 ENI/IP management permissions in the vpc-cni policy (required for the addon to actually manage pod networking, not just tag ENIs)"
  type        = bool
  default     = true
}

variable "attach_ebs_csi_policy" {
  type    = bool
  default = false
}

variable "attach_cluster_autoscaler_policy" {
  type    = bool
  default = false
}

variable "cluster_autoscaler_cluster_names" {
  description = "Cluster name(s) the cluster-autoscaler policy is scoped to (required when attach_cluster_autoscaler_policy is true)"
  type        = list(string)
  default     = []
}

variable "attach_load_balancer_controller_policy" {
  type    = bool
  default = false
}

variable "custom_policy_json" {
  description = "Optional custom IAM policy document (JSON) to attach, for use cases with no built-in policy (e.g. Secrets Manager or S3 bucket access)"
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "Existing AWS-managed (or customer-managed) IAM policy ARNs to attach, for cases with no attach_* flag in the upstream submodule (e.g. CloudWatchAgentServerPolicy)"
  type        = list(string)
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
