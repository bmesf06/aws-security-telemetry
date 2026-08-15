output "log_bucket_name" {
  value       = aws_s3_bucket.telemetry_logs.id
  description = "Name of the secure S3 log vault bucket"
}

output "kms_key_arn" {
  value       = aws_kms_key.log_key.arn
  description = "ARN of the KMS Key securing the logs"
}

output "sns_topic_arn" {
  value       = aws_sns_topic.security_alerts.arn
  description = "ARN of the SNS topic sending real-time security alerts"
}
