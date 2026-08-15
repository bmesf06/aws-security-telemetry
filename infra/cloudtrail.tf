# CloudTrail Trail to log all account management events
resource "aws_cloudtrail" "main" {
  name                          = "${var.project_prefix}-trail"
  s3_bucket_name                = aws_s3_bucket.telemetry_logs.id
  kms_key_id                    = aws_kms_key.log_key.arn
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  # Event selectors: Capture all Read and Write management events
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  depends_on = [aws_s3_bucket_policy.telemetry_logs_policy]
}
