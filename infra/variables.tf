variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project_prefix" {
  type    = string
  default = "sec-telemetry"
}
variable "alert_email" {
  type        = string
  description = "Email address for SNS security alert notifications."
}
