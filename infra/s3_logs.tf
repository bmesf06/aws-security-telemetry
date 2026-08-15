# 1. Random string to make bucket name globally unique
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# 2. Cryptographic key for encrypting logs
resource "aws_kms_key" "log_key" {
  description             = "KMS key for CloudTrail and Config log encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "Enable IAM User Permissions"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "Allow CloudTrail to encrypt logs"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = ["kms:GenerateDataKey*", "kms:DescribeKey"]
        Resource  = "*"
      },
      {
        Sid       = "Allow Config to encrypt logs"
        Effect    = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = ["kms:GenerateDataKey*", "kms:Decrypt"]
        Resource  = "*"
      }
    ]
  })
}

# 3. Secure S3 Bucket
resource "aws_s3_bucket" "telemetry_logs" {
  bucket        = "${var.project_prefix}-logs-${random_string.suffix.result}"
  force_destroy = true
}

# 4. Enforce Public Access Blocks
resource "aws_s3_bucket_public_access_block" "telemetry_logs" {
  bucket                  = aws_s3_bucket.telemetry_logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 5. Lifecycle rule to delete logs after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "telemetry_logs" {
  bucket = aws_s3_bucket.telemetry_logs.id

  rule {
    id     = "expire-logs"
    status = "Enabled"
    expiration {
      days = 30
    }
  }
}

# 6. Default Server-Side Encryption Settings
resource "aws_s3_bucket_server_side_encryption_configuration" "telemetry_logs" {
  bucket = aws_s3_bucket.telemetry_logs.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.log_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

# 7. Comprehensive Bucket Policy for CloudTrail and AWS Config
resource "aws_s3_bucket_policy" "telemetry_logs_policy" {
  bucket = aws_s3_bucket.telemetry_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnforceSSLOnly"
        Effect = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.telemetry_logs.arn,
          "${aws_s3_bucket.telemetry_logs.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      },
      {
        Sid    = "AllowCloudTrailAclCheck"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.telemetry_logs.arn
      },
      {
        Sid    = "AllowCloudTrailWrite"
        Effect = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.telemetry_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      },
      {
        Sid    = "AllowConfigAclCheck"
        Effect = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.telemetry_logs.arn
      },
      {
        Sid    = "AllowConfigWrite"
        Effect = "Allow"
        Principal = { Service = "config.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.telemetry_logs.arn}/Config/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

# Data element to look up your account details dynamically
data "aws_caller_identity" "current" {}
