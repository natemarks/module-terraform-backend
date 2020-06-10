# aws-environments/natemarks/terraform/shared/terragrunt.hcl
remote_state {
  backend = "local"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    path = "terraform.tfstate"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------

inputs = {
  aws_region     = "us-east-1"
  aws_account_id = "0123456789"
  aws_account_alias = "my_account_alist"
  s3_replication_destination_region = "us-west-2"
  organization_id = "com.my-org."
  lock_table_name = "terragrunt-lock-table"
}

