# Tripwire Rule: Detects Root Login, Security Group 0.0.0.0/0 changes, or Log Tampering
resource "aws_cloudwatch_event_rule" "risky_activity" {
  name        = "${var.project_prefix}-risky-activity-rule"
  description = "Triggers on Root login, open SG rules, or CloudTrail tampering"

  event_pattern = jsonencode({
    source        = ["aws.ec2", "aws.cloudtrail", "aws.iam"]
    "detail-type" = ["AWS API Call via CloudTrail", "AWS Console Sign-In via CloudTrail"]
    detail = {
      eventName = [
        "ConsoleLogin",
        "AuthorizeSecurityGroupIngress",
        "StopLogging",
        "DeleteTrail"
      ]
    }
  })
}

# Target: Direct the EventBridge Rule to publish to our SNS Email Topic
resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.risky_activity.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.security_alerts.arn
}
