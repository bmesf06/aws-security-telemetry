\# AWS Cloud Security Telemetry \& Automated Audit Pipeline



An enterprise-grade, automated AWS security telemetry architecture provisioned entirely as code using HashiCorp Terraform and analyzed programmatically via Python (`boto3`). This project establishes a localized Security Operations Center (SOC) logging framework, continuous configuration auditing, real-time behavioral tripwires, and localized log reduction. 



The architecture is explicitly designed to map technical cloud implementations to \*\*NIST SP 800-171 Rev. 2\*\* (Audit \& Accountability) and \*\*CMMC 2.0\*\* defensive tracking standards.



\---



\## 🏛️ System Architecture



```text

&#x20;      \[ Enterprise AWS Account Infrastructure Activity ]

&#x20;                              │

&#x20;      ┌───────────────────────┴───────────────────────┐

&#x20;      ▼                                               ▼

\[ AWS CloudTrail Engine ]                   \[ AWS Config Rules Engine ]

&#x20; │ (Account-Wide Cam)                        │ (Compliance Monitoring)

&#x20; │                                           │

&#x20; ├──> Enforce SSL/TLS In-Transit             ├──> Evaluate Root MFA Status

&#x20; ├──> Enable Cryptographic Hash Checks       └──> Inventory S3 Public Flags

&#x20; │                                           │

&#x20; ▼                                           ▼

\[ Secure S3 Telemetry Log Vault (SSE-KMS Customer-Managed Keys) ]

&#x20; │

&#x20; ├──> Automatic Data Sharding \& Folder Partitioning (/AWSLogs, /Config)

&#x20; └──> Automated Lifecycle Shredder (Enforce Hard 30-Day Expiration)

&#x20; │

&#x20; ▼ (Event Ingestion Loop)

\[ Local Python Parser: parse\_alerts.py (boto3 SDK Architecture) ]

&#x20; │

&#x20; ├──> Query S3 Metastore \& Discover Active Logging Targets

&#x20; ├──> Stream Compressed .json.gz Files Directly to System Memory

&#x20; └──> Isolate and Extract High-Risk Incident Triggers (StopLogging, ConsoleLogin)

&#x20; │

&#x20; ▼

\[ On-Demand Executive Security Operations Audit Summary Report ]

```



\---



\## 🛡️ Core Capabilities \& Compliance Matrix



| Security Control | Technical Implementation | NIST SP 800-171 Mapping |

| :--- | :--- | :--- |

| \*\*Audit Logging\*\* | Continuous tracking of management and infrastructure operations written directly to immutable cloud objects. | \*\*3.3.1\*\* (System Audit Logs) |

| \*\*Log Integrity \& Tamper Proofing\*\* | Native cryptographic validation via log-file hashing combined with customer-managed SSE-KMS ledger rotation. | \*\*3.3.8\*\* (Protect Audit Information) |

| \*\*Configuration Compliance\*\* | Continual automated tracking of administrative posture (MFA enforcement) and boundary safeguards. | \*\*3.4.2\*\* (Security Configurations) |

| \*\*Real-time Incident Tripwires\*\* | Amazon EventBridge intercept patterns capturing intrusive operations to broadcast instant escalations. | \*\*3.3.4\*\* (Audit Failure Alarms) |

| \*\*Log Reduction \& Sifting\*\* | Localized Python scripts handling dynamic batch data minimization to extract actionable indicators of compromise. | \*\*3.3.6\*\* (Audit Record Ingestion) |



\---



\## 💻 Custom Python Ingestion Engine (`parse\_alerts.py`)



Raw cloud trail telemetry is written by AWS as multi-layered, heavily nested `.json.gz` file packages sharded across deep directories. Sifting through millions of lines of raw text manually during an investigation is impossible. 



To solve this, `parse\_alerts.py` serves as a programmatic data minimization utility using the \*\*AWS SDK for Python (`boto3`)\*\*:



1\. \*\*Dynamic Target Discovery\*\*: Connects directly to the S3 API to map out buckets holding the specialized `sec-telemetry-lab-logs` naming token.

2\. \*\*In-Memory Decompression\*\*: Downloads data streams and utilizes the Python `gzip` library to unpack tracking records inside volatile RAM, guaranteeing that storage isn't cluttered with uncompressed intermediate assets.

3\. \*\*Behavioral Key Filtering\*\*: Evaluates record sets specifically searching for malicious indicators:

&#x20;  \* `StopLogging` / `DeleteTrail`: Indicators of active detection evasion or log tampering.

&#x20;  \* `AuthorizeSecurityGroupIngress`: Detection of perimeter network firewall exposure (unrestricted `0.0.0.0/0` rules).

&#x20;  \* `ConsoleLogin`: Tracking administrative logins to monitor critical root account posture.



\---



\## 📸 Verified Infrastructure \& Analytics Proof



\### 1. Active EventBridge Alert Tripwires

Here is the automated configuration tracking rule engine deployed via Terraform live within the AWS Management Console:

!\[EventBridge Cloud Security Architecture Proof](docs/AWSConsEventbridge.png)



\### 2. In-Memory Python Log Reduction Summary

Our localized SecOps parser successfully evaluating compressed S3 shards and extracting high-risk malicious activity indicators:

!\[Python boto3 Ingestion Tool Proof](docs/parse\_alert.png)



\---



\## 📁 Repository Directory Structure



```text

aws-security-telemetry/

├── .github/

│   └── workflows/

│       └── terraform-ci.yml    # Automated Linting, Formatting, \& Syntax Validation

├── docs/

│   ├── AWSConsEventbridge.png # Verified EventBridge Active Tripwire Guardrails

│   └── parse\_alert.png        # Custom Python Ingestion Engine Execution Evidence

├── infra/

│   ├── provider.tf            # AWS Provider Configuration \& Global Compliance Tags

│   ├── variables.tf           # Centralized Variable Declarations (Region, Prefix)

│   ├── terraform.tfvars       # Input Variable Variables (Ignored via .gitignore)

│   ├── s3\_logs.tf             # Enforced SSL Bucket Policies, Public Access Blocks, KMS

│   ├── cloudtrail.tf          # Cryptographic Log Verification \& Account-Wide Cameras

│   ├── config.tf              # AWS Config Recorder \& Compliance Rules

│   ├── eventbridge.tf         # Automated Tripwire Definitions for Suspicious Calls

│   ├── sns.tf                 # Alerts Megaphone Enforcing Email Delivery Configurations

│   └── outputs.tf             # Core System Output Tracking Exports

├── scripts/

│   ├── requirements.txt       # Programmatic Dependencies (boto3 Tracking SDK)

│   └── parse\_alerts.py        # Executive Summary Python Processing Engine

└── .gitignore                 # Enforces Exclusion of tfstate, Secrets, and IDE Folders

```



\---



\## 🧹 Infrastructure De-provisioning



To wipe out deployed structures and prevent ongoing cloud resource consumption, clean up your environment using the orchestration cleanup utility:

```bash

cd infra

terraform destroy

```



