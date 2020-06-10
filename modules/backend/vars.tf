# Configure / Initialize Terraform Variables

variable "aws_region" {
  type = string
  default = "us-east-1"
}

variable "aws_account_id" {
  type = string
}


variable "s3_replication_destination_region" {
  type = string
  default = "us-west-2"
}

variable "organization_id" {
  type = string
  default = "com.my-organization."
}