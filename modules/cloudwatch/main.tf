# One log group per entry in var.log_group_names (e.g. node group, app logs).
resource "aws_cloudwatch_log_group" "this" {
  for_each = var.log_group_names

  name              = each.value
  retention_in_days = var.retention_in_days

  tags = var.tags
}
