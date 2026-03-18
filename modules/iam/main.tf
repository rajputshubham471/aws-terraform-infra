# ============================================================
# modules/iam/main.tf
#
# Creates an IAM Role for EC2 instances to access S3.
#
# HOW IAM ROLES WORK (the RIGHT way to give EC2 access to S3):
#
# ❌ WRONG:  Hardcode AWS_ACCESS_KEY and AWS_SECRET_KEY on the server
#            → If someone hacks your EC2, they steal your credentials
#
# ✅ RIGHT:  Attach an IAM Role to the EC2 instance
#            → AWS automatically provides temporary credentials
#            → Credentials rotate automatically, no secrets on disk
#
# COMPONENTS:
# 1. IAM Role          — The identity (who/what are you?)
# 2. Trust Policy      — Who can ASSUME this role? (EC2 service)
# 3. IAM Policy        — What can the role DO? (read/write S3)
# 4. Instance Profile  — Wrapper that attaches a Role to EC2
# ============================================================

# ── IAM Role ─────────────────────────────────────────────────
resource "aws_iam_role" "ec2_role" {
  name        = "${var.project_name}-${var.environment}-ec2-role"
  description = "IAM role for EC2 instances to access S3"

  # Trust Policy — answers: "Who is allowed to assume this role?"
  # Here we say: "The EC2 service (ec2.amazonaws.com) can assume this role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowEC2ToAssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-ec2-role"
  }
}

# ── IAM Policy ───────────────────────────────────────────────
# Defines WHAT the role can do.
# Principle of Least Privilege: only grant minimum necessary permissions
resource "aws_iam_policy" "s3_access" {
  name        = "${var.project_name}-${var.environment}-s3-access-policy"
  description = "Allows EC2 instances to read/write to the project S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3BucketOperations"
        Effect = "Allow"
        Action = [
          "s3:GetObject",      # Download files
          "s3:PutObject",      # Upload files
          "s3:DeleteObject",   # Delete files
          "s3:ListBucket",     # List files in bucket
        ]
        Resource = [
          var.s3_bucket_arn,          # The bucket itself (for ListBucket)
          "${var.s3_bucket_arn}/*"    # All objects inside the bucket
        ]
      },
      {
        Sid    = "AllowCloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Resource = "*"
        # This lets EC2 send logs to CloudWatch for monitoring
      }
    ]
  })
}

# ── Attach Policy to Role ─────────────────────────────────────
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# ── Instance Profile ──────────────────────────────────────────
# EC2 doesn't use IAM Roles directly — it needs an Instance Profile
# (a container that wraps the role) to attach it to an instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}
