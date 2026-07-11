variable "repository_name" {
  type = string
}

variable "image_tag_mutability" {
  type    = string
  default = "IMMUTABLE"
}

variable "untagged_expiry_days" {
  type    = number
  default = 14
}

variable "tagged_count_to_keep" {
  type    = number
  default = 20
}

variable "tags" {
  type    = map(string)
  default = {}
}
