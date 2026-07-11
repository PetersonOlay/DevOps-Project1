variable "log_group_names" {
  description = "Map of logical name => CloudWatch log group name to create (e.g. node group, app logs)"
  type        = map(string)
}

variable "retention_in_days" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
