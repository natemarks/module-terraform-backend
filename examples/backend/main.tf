# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CREATE AN APP VPC
# Launch a VPC that can be used as a production or staging environment for your apps.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

terraform {
  required_version = ">= 0.12"
}

# ---------------------------------------------------------------------------------------------------------------------
# CONFIGURE OUR AWS CONNECTION
# ---------------------------------------------------------------------------------------------------------------------

provider "aws" {
  # The AWS region in which all resources will be created
  region = var.aws_region
}

# ---------------------------------------------------------------------------------------------------------------------
# CREATE SSM policies for EC2 Instances
# ---------------------------------------------------------------------------------------------------------------------


module "backend" {

  source = "git::git@github.com:natemarks/module-terraform-backend.git//modules/backend?ref=v0.0.1"

  aws_region = var.aws_region
  aws_account_id = var.aws_account_id
  organization_id = var.organization_id
  s3_replication_destination_region = var.s3_replication_destination_region
  lock_table_name = var.lock_table_name
}
