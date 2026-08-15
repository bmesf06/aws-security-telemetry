# 1. SNS Topic for Security Alerts
resource "aws_sns_topic" "security_alerts" {
  name = "${var.project_prefix}-alerts-topic"
}

# 2. Email Subscription to receive alerts
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.security_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# 3. Topic Policy allowing EventBridge to publish alerts
resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.security_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowEventBridgeToPublish"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sns:Publish"
        Resource  = aws_sns_topic.security_alerts.arn
      }
    ]
  })
}
