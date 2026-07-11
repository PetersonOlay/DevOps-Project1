output "state_bucket_name" {
  description = "Name of the S3 bucket holding Terraform state"
  value       = aws_s3_bucket.state.id
}

output "state_bucket_arn" {
  value = aws_s3_bucket.state.arn
}

output "lock_table_name" {
  description = "Name of the DynamoDB table used for state locking"
  value       = aws_dynamodb_table.lock.name
}
