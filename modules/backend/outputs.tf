output "backend_bucket_id" {
  value = aws_s3_bucket.backend_bucket.id
}

output "terraform_lock_table" {
  value = aws_dynamodb_table.terraform_state_lock.name
}

output "backend_region" {
  value = var.aws_region
}