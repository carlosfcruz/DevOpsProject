# ─────────────────────────────────────────────────────────
# State Backend Resources
# ─────────────────────────────────────────────────────────
# These create the S3 bucket and DynamoDB table that will
# store Terraform state remotely (we'll migrate in Session 6).
#
# WHY remote state?
#   - Local .tfstate = single point of failure on your laptop
#   - S3 = versioned, durable, shared with your team
#   - DynamoDB = prevents two people from applying at once
# ─────────────────────────────────────────────────────────

# ───── S3 Bucket: stores the terraform.tfstate file ─────
resource "aws_s3_bucket" "terraform_state" {
  bucket = "opspilot-terraform-state-${data.aws_caller_identity.current.account_id}"

  # Prevent accidental deletion of this bucket
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name    = "Terraform State"
    Purpose = "Stores Terraform remote state"
  }
}

# Enable versioning — so you can roll back bad state
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt state at rest (it may contain secrets)
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block all public access — state files are private
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ───── DynamoDB Table: state locking ─────
# When someone runs `terraform apply`, this table locks
# the state so nobody else can apply at the same time.
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "opspilot-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name    = "Terraform State Locks"
    Purpose = "Prevents concurrent state modifications"
  }
}

# ───── Data source: get current AWS account ID ─────
# Used to make the S3 bucket name globally unique
data "aws_caller_identity" "current" {}
