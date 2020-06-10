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
# Create the s3 backend bucket and access_block
# -------------------------------------------------------------------------------------



resource "aws_s3_bucket" "backend_bucket" {
  bucket = "${var.organization_id}${var.aws_account_number}-terragrunt-remote-state"
  acl    = "private"
  versioning {
    enabled = true
  }
  replication_configuration {
    role = aws_iam_role.replication.arn

    rules {
      id = "Terraform-State-Replication"
      status = "Enabled"
      destination {
        bucket = aws_s3_bucket.replication_destination.arn
      }
    }
  }

 tags = {
    Name      = aws_s3_bucket.backend_bucket.id
    terraform = "true"
    terragrunt = "true"
  }

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
  bucket = "${var.organization_id}${var.aws_account_number}-terragrunt-remote-state-replication"
  acl    = "private"
  region   = var.s3_replication_destination_region
  provider = aws.repl_region

  versioning {
    enabled = true
  }

  tags = {
    Name      = aws_s3_bucket.replication_destination.id
    terraform = "false"
  }
}


resource "aws_s3_bucket_public_access_block" "tfstate_repl_public_block" {
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
  name = "s3crr_${var.aws_account_number}-tf-remote-state-repl"
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
  name = "s3crr_${var.aws_account_number}-tf-remote-state-repl"
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
                "arn:aws:s3:::${aws_s3_bucket.backend_bucket.id},
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

  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}


resource "aws_dynamodb_table" "terraform_state_lock" {
  name           = "terraform-lock"
  read_capacity  = 5
  write_capacity = 5
  hash_key       = "LockID"
  attribute {
      name = "LockID"
      type = "S"
    }

  tags = {
    Name      = "lock-table-${var.aws_account_number}-terragrunt-remote-state"
    terraform = "true"
    terragrunt = "true"
  }
}