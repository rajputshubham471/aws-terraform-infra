# ============================================================
# modules/s3/main.tf
#
# Creates a production-grade S3 bucket with:
# - Globally unique name (uses random suffix)
# - Versioning (keeps history of all file changes)
# - Server-side encryption (data encrypted at rest)
# - All public access blocked (private bucket)
# - Lifecycle rules (auto-delete old versions to save cost)
#
# WHY ALL THIS?
# A plain bucket with default settings is insecure.
# These settings follow AWS security best practices.
# ============================================================

# Random suffix to make bucket name globally unique
# S3 bucket names must be unique across ALL AWS accounts worldwide
resource "random_id" "bucket_suffix" {
  byte_length = 4   # Generates 8 hex chars e.g. "a3f2b1c9"
}

resource "aws_s3_bucket" "main" {
  # Bucket name = project-env-random (e.g. rahul-devops-dev-a3f2b1c9)
  bucket = "${var.project_name}-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = {
    Name = "${var.project_name}-${var.environment}-bucket"
  }
}

# ── Block ALL public access ───────────────────────────────────
# This is a safety net — even if someone adds a bad bucket policy,
# public access will still be blocked
resource "aws_s3_bucket_public_access_block" "main" {
  bucket = aws_s3_bucket.main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── Enable Versioning ─────────────────────────────────────────
# Every overwrite creates a new VERSION instead of destroying the old one
# You can restore previous versions if something goes wrong
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = "Enabled"
  }
}

# ── Server-Side Encryption ────────────────────────────────────
# Encrypts all files automatically when stored (AES-256)
resource "aws_s3_bucket_server_side_encryption_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true   # Reduces KMS API calls (cost saving)
  }
}

# ── Lifecycle Rule ────────────────────────────────────────────
# Automatically delete old non-current versions after 30 days
# Prevents storage costs from accumulating indefinitely
resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id

  # Must have versioning enabled first
  depends_on = [aws_s3_bucket_versioning.main]

  rule {
    id     = "cleanup-old-versions"
    status = "Enabled"

    # Applies to all objects in the bucket
    filter {}

    # Delete non-current (old) versions after 30 days
    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

# Required for random_id resource
terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
