output "log_group_arns" {
  value = { for k, v in aws_cloudwatch_log_group.this : k => v.arn }
}

output "log_group_names" {
  value = { for k, v in aws_cloudwatch_log_group.this : k => v.name }
}
