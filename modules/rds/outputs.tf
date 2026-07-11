output "db_instance_endpoint" {
  description = "Connection endpoint (host:port)"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_address" {
  description = "Host only, no port"
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  value = aws_db_instance.this.port
}

output "db_name" {
  value = aws_db_instance.this.db_name
}

output "master_user_secret_arn" {
  description = "ARN of the AWS-managed Secrets Manager secret holding the master credentials"
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "security_group_id" {
  value = aws_security_group.this.id
}
