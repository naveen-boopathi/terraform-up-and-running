output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform-state-file.arn
  description = "The ARN of the s3 bucket"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform-locks.name
  description = "The name of the DynamoDB table"
}
