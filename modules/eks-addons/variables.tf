variable "cluster_name" {
  type = string
}

variable "vpc_cni_role_arn" {
  type = string
}

variable "ebs_csi_role_arn" {
  type = string
}

variable "cloudwatch_observability_role_arn" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
