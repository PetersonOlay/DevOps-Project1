# Inputs for the placeholder secret (see main.tf).
variable "secret_name" {
  type = string
}

variable "placeholder_value" {
  description = "Initial placeholder JSON string; the app team overwrites this out-of-band later"
  type        = string
  default     = "{\"placeholder\":true}"
}

variable "recovery_window_in_days" {
  description = "Days AWS retains a deleted secret before permanent removal (0 disables recovery)"
  type        = number
  default     = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}
