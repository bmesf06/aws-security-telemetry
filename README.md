# AWS Cloud Security Telemetry & Automated Audit Pipeline

An automated AWS security telemetry pipeline built with HashiCorp Terraform and Python (boto3). This project enforces cloud logging, configuration compliance, real-time alert routing, and custom log parsing for security event analysis. Designed to align with NIST SP 800-171 Rev. 2 (Audit & Accountability) compliance requirements.

## ??? System Architecture
[ AWS Account Activity ] -> AWS CloudTrail (KMS Encrypted) -> S3 Log Vault (30-day Lifecycle)

## ?? Custom Python Log Parser (parse_alerts.py)
Raw AWS log exports are delivered as gzipped JSON files split across nested S3 bucket paths. To make this data actionable for an analyst, parse_alerts.py automates the ingestion process by utilizing boto3 to locate the project S3 log bucket dynamically, downloading streams, and extracting critical API actions like StopLogging.
