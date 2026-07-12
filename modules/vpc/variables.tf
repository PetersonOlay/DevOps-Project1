# Inputs for the VPC (see main.tf).
variable "name" {
  description = "Name prefix for the VPC and its resources"
  type        = string
}

variable "cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
}

variable "private_subnets" {
  description = "CIDR blocks for private subnets, one per AZ"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR blocks for public subnets, one per AZ"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "Use a single shared NAT gateway instead of one per AZ"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "EKS cluster name, used for the shared subnet tag"
  type        = string
}

variable "tags" {
  description = "Common tags applied to all VPC resources"
  type        = map(string)
  default     = {}
}
