variable "user_name" {
  description = "Name for the CI deployer IAM user"
  type        = string
}

variable "ecr_repository_arn" {
  description = "ARN of the environment's ECR repository, scopes the push permissions"
  type        = string
}

variable "eks_cluster_arn" {
  type = string
}

variable "eks_cluster_name" {
  type = string
}

variable "kubernetes_namespace" {
  description = "Namespace this user's EKS access entry is scoped to"
  type        = string
  default     = "default"
}

variable "tags" {
  type    = map(string)
  default = {}
}
