# Configure / Initialize Terraform Variables

variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}


variable "s3_replication_destination_region" {
  type = string
}

variable "organization_id" {
  type = string
}

variable "lock_table_name" {
  type = string
}