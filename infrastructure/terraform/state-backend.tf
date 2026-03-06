# ─────────────────────────────────────────────────────────
# State Backend Resources
# ─────────────────────────────────────────────────────────
# Provisions the S3 bucket and DynamoDB table necessary for
# remote state storage and locking mechanisms.
#
# Remote state provides:
#   - Durability and versioning (S3)
#   - Concurrency control and state locking (DynamoDB)
# ─────────────────────────────────────────────────────────

# ───── S3 Bucket ─────
# Stores the terraform.tfstate file remotely.
resource "aws_s3_bucket" "terraform_state" {
  bucket = "platform-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name    = "Terraform State"
    Purpose = "Stores Terraform remote state"
  }
}

# Enables object versioning for state history and rollback capability.
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Configures default encryption at rest using AES256.
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Enforces strict block of public access for the state bucket.
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ───── DynamoDB Table ─────
# Facilitates state locking during concurrent apply operations
# to prevent state corruption.
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "platform-terraform-locks"
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

# ───── Identity Data Source ─────
# Retrieves the operational AWS account ID to ensure global 
# uniqueness for the S3 bucket name.
data "aws_caller_identity" "current" {}
