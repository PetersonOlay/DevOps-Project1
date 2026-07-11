variable "user_name" {
  description = "Name for the CI deployer IAM user"
  type        = string
}

variable "ecr_repository_arns" {
  description = "ARNs of the environment's ECR repositories (backend, frontend, ...), scopes the push permissions"
  type        = list(string)
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
