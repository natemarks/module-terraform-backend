output "backend_bucket_id" {
  value = aws_s3_bucket.backend_bucket.id
}

output "lock_table_name" {
  value = aws_dynamodb_table.terraform_state_lock.name
}

output "replication_bucket_id" {
  value = aws_s3_bucket.replication_destination[0].id
}