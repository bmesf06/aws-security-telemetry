# 1. IAM Role for AWS Config service
resource "aws_iam_role" "config_role" {
  name = "${var.project_prefix}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

# Attach AWS managed policy for Config service permissions
resource "aws_iam_role_policy_attachment" "config_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# 2. AWS Config Recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "${var.project_prefix}-config-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# 3. AWS Config Delivery Channel (Sends snapshots to S3)
resource "aws_config_delivery_channel" "main" {
  name           = "${var.project_prefix}-config-delivery"
  s3_bucket_name = aws_s3_bucket.telemetry_logs.id
  s3_key_prefix  = "Config"
  sns_topic_arn  = null

  depends_on = [aws_config_configuration_recorder.main]
}

# Enable the recorder
resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.main]
}

# 4. Compliance Rule 1: Ensure root account has MFA enabled
resource "aws_config_config_rule" "root_mfa" {
  name        = "root-account-mfa-enabled"
  description = "Checks whether the root user has MFA enabled."

  source {
    owner             = "AWS"
    source_identifier = "ROOT_ACCOUNT_MFA_ENABLED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]
}

# 5. Compliance Rule 2: Ensure S3 buckets prohibit public write access
resource "aws_config_config_rule" "s3_public_write" {
  name        = "s3-bucket-public-write-prohibited"
  description = "Checks that S3 buckets do not allow public write permissions."

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_WRITE_PROHIBITED"
  }

  depends_on = [aws_config_configuration_recorder_status.main]
}
