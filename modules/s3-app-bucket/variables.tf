variable "bucket_name" {
  description = "Globally unique S3 bucket name (include account ID/env to ensure uniqueness)"
  type        = string
}

variable "force_destroy" {
  description = "Allow bucket deletion even if it contains objects (true for dev/stg, false for prod)"
  type        = bool
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
