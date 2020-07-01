# Configure the AWS Provider
provider "aws" {
  region = var.aws_region
}



# -------------------------------------------------------------------------------------
# Policy document that requires TLS to S3
# -------------------------------------------------------------------------------------
data "aws_iam_policy_document" "require_secure_transport" {
  statement {
    sid = "DenyInsecureCommunications"
    actions = [
      "s3:*"
    ]
    effect = "Deny"
    principals {
      identifiers = ["*"]
      type = "*"
    }
    resources = [
      "${aws_s3_bucket.backend_bucket.arn}/*",
      aws_s3_bucket.backend_bucket.arn
    ]
    condition {
      test = "Bool"
      values = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}



# -------------------------------------------------------------------------------------
# Attach TLS policy to backend_bucket
# -------------------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "backend_bucket_secure_comm" {
  bucket = aws_s3_bucket.backend_bucket.id
  policy = data.aws_iam_policy_document.require_secure_transport.json
}


# -------------------------------------------------------------------------------------
# Create the s3 backend bucket and access_block
# -------------------------------------------------------------------------------------
resource "aws_s3_bucket" "backend_bucket" {
  bucket = "${var.organization_id}${var.aws_account_id}-terragrunt-remote-state"
  acl    = "private"
  versioning {
    enabled = true
  }
  logging {
    target_bucket = "${var.organization_id}${var.aws_account_id}-terragrunt-remote-state"
    target_prefix = "TFStateLogs/"
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }

 tags = merge({
    Name      = "${var.organization_id}${var.aws_account_id}-terragrunt-remote-state"
    terraform = "true"
    terragrunt = "true"
  },
 var.custom_tags)

}

# -------------------------------------------------------------------------------------
# Set the public access block on backend_bucket
# -------------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "tfstate_backend_bucket_public_block" {
  bucket = aws_s3_bucket.backend_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}




# -------------------------------------------------------------------------------------
# Create the dynamodb lock table
# -------------------------------------------------------------------------------------
resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = var.lock_table_name
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"
  attribute {
      name = "LockID"
      type = "S"
    }

  tags = {
    Name      = "lock-table-${var.aws_account_id}-terragrunt-remote-state"
    terraform = "true"
    terragrunt = "true"
  }
}