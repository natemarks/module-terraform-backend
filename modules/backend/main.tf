# Configure the AWS Provider
provider "aws" {
  region = var.aws_region

  version = "~> 2.24.0"
}

provider "aws" {
  region = var.s3_replication_destination_region
  alias = "repl_region"

  version = "~> 2.24.0"
}


# -------------------------------------------------------------------------------------
# Add policy to require secure transport on the backend bucket
# -------------------------------------------------------------------------------------
data "aws_iam_policy_document" "backend_bucket_secure_transport" {
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
      "${aws_s3_bucket.backend_bucket.arn}"
    ]
    condition {
      test = "Bool"
      values = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}

resource "aws_s3_bucket_policy" "disable_insecure_s3_communications" {
  bucket = aws_s3_bucket.backend_bucket.id
  policy = data.aws_iam_policy_document.backend_bucket_secure_transport.json
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
        kms_master_key_id = "aws/s3"
        sse_algorithm     = "aws:kms"
      }
    }
  }
  replication_configuration {
    role = aws_iam_role.replication.arn

    rules {
      id = "Terragrunt-State-Replication"
      status = "Enabled"
      destination {
        bucket = aws_s3_bucket.replication_destination.arn
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



resource "aws_s3_bucket_public_access_block" "tfstate_backend_bucket_public_block" {
  bucket = aws_s3_bucket.backend_bucket.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}


# -------------------------------------------------------------------------------------
# Create the replication s3 backend bucket and access_block
# -------------------------------------------------------------------------------------


resource "aws_s3_bucket" "replication_destination" {
  count = var.enable_replication_bucket ? 1 : 0

  bucket = "${var.organization_id}${var.aws_account_id}-terragrunt-repl"
  acl    = "private"
  region   = var.s3_replication_destination_region
  provider = aws.repl_region

  versioning {
    enabled = true
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "AES256"
      }
    }
  }

 tags = merge({
    Name      = "${var.organization_id}${var.aws_account_id}-terragrunt-repl"
    terraform = "true"
    terragrunt = "true"
  },
 var.custom_tags)
}


resource "aws_s3_bucket_policy" "tls_for_replication_bucket" {
  count = var.enable_replication_bucket ? 1 : 0

  bucket = aws_s3_bucket.replication_destination.id
  policy = data.aws_iam_policy_document.backend_bucket_secure_transport.json
}
resource "aws_s3_bucket_public_access_block" "tfstate_repl_public_block" {
  count = var.enable_replication_bucket ? 1 : 0

  provider = aws.repl_region
  bucket = aws_s3_bucket.replication_destination.id


  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}


# -------------------------------------------------------------------------------------
# Configure bucket replicaton
# -------------------------------------------------------------------------------------



resource "aws_iam_role" "replication" {
  count = var.enable_replication_bucket ? 1 : 0

  name = "s3crr_${var.aws_account_id}-terragrunt-repl"
  path   = "/service-role/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "s3.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "replication" {
  count = var.enable_replication_bucket ? 1 : 0

  name = "s3crr_${var.aws_account_id}-terragrunt-repl"
  path   = "/service-role/"
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "s3:Get*",
                "s3:ListBucket"
            ],
            "Effect": "Allow",
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.backend_bucket.id}",
                "arn:aws:s3:::${aws_s3_bucket.backend_bucket.id}/*"
            ]
        },
        {
            "Action": [
                "s3:ReplicateObject",
                "s3:ReplicateDelete",
                "s3:ReplicateTags",
                "s3:GetObjectVersionTagging"
            ],
            "Effect": "Allow",
            "Resource": "arn:aws:s3:::${aws_s3_bucket.replication_destination.id}/*"
        }
    ]
}
POLICY
}


resource "aws_iam_role_policy_attachment" "replication" {
  count = var.enable_replication_bucket ? 1 : 0

  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}


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