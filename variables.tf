# ----------------------------------------------------------------------------------
# GLOBAL CONFIGURATION VARIABLES
# ----------------------------------------------------------------------------------

# Project Name: Used as a prefix for all resources (e.g., S3 buckets, KMS keys).
variable "project_name" {
  description = "A short, unique name for the project, used to prefix resource names."
  type        = string
  default     = "hipaa-hitrust-demo"
}

# Environment Tag: Identifies the deployment environment (e.g., prod, staging, dev).
variable "environment" {
  description = "The deployment environment (e.g., prod, staging, dev)."
  type        = string
  default     = "dev"
}

# AWS Region: Where all resources will be provisioned.
variable "aws_region" {
  description = "The AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"
}

# ----------------------------------------------------------------------------------
# S3 COMPLIANCE CONFIGURATION
# ----------------------------------------------------------------------------------

# S3 Object Lock Retention Period: Used for data integrity requirements (optional but recommended for PHI).
# This is a key control for HITRUST/HIPAA non-repudiation and integrity.
variable "retention_period_days" {
  description = "The minimum retention period (in days) for objects in the data bucket using Object Lock (Governance Mode). Set to 0 to disable Object Lock."
  type        = number
  default     = 365
}

# S3 Access Log Retention Period: How long to keep access logs in the separate logging bucket.
# Required for Auditing controls (HIPAA/HITRUST).
variable "logging_bucket_retention_days" {
  description = "The number of days to retain access logs in the logging bucket before automatic deletion."
  type        = number
  default     = 1825 # 5 years
}

# ----------------------------------------------------------------------------------
# KMS KEY ACCESS CONFIGURATION
# ----------------------------------------------------------------------------------

# KMS Key Administrators: ARNs of IAM users or roles that are allowed to manage (but not necessarily use) the KMS key.
# This aligns with Least Privilege and Administrative Safeguards.
variable "kms_key_administrator_arns" {
  description = "A list of IAM ARNs (users or roles) that will be granted administrative permissions on the KMS CMK."
  type        = list(string)
  default     = [] # Must be populated with actual ARNs in a real deployment
}

# KMS Key Users: ARNs of IAM users or roles that are allowed to encrypt/decrypt data using the KMS key.
# These will typically be your application roles.
variable "kms_key_user_arns" {
  description = "A list of IAM ARNs (users or roles) that will be granted usage (encrypt/decrypt) permissions on the KMS CMK."
  type        = list(string)
  default     = [] # Must be populated with actual ARNs in a real deployment
}

