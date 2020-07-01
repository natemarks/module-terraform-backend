# Configure / Initialize Terraform Variables

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "aws_account_id" {
  type = string
}

variable "organization_id" {
  type = string
  default = "com.my-organization."
}

variable "lock_table_name" {
  type = string
  default = "terragrunt-lock-table"
}

variable "enable_replication_bucket" {
  description = "Set to true if you want to replicate the backend bucket to a bucket in a different region"
  type        = bool
  default     = false
}

variable "s3_replication_destination_region" {
  type = string
  default = "us-west-2"
}

variable "custom_tags" {
  description = "A map of key value pairs that represents custom tags to apply to taggable resources"
  type        = map(string)
  default     = {
    terraform = "true"
    terragrunt = "true"
  }
}