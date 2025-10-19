# ----------------------------------------------------------------------------------
# MODULE INPUT VARIABLES
# These variables receive values passed from the root 'main.tf' configuration.
# ----------------------------------------------------------------------------------

variable "project_name" {
  description = "Project name tag/prefix."
  type        = string
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)."
  type        = string
}

variable "aws_region" {
  description = "The AWS region where resources are deployed."
  type        = string
}

variable "retention_period_days" {
  description = "The minimum retention period (in days) for Object Lock (HIPAA Integrity control)."
  type        = number
}

variable "logging_bucket_retention_days" {
  description = "The number of days to retain access logs."
  type        = number
}

# CRITICAL INPUT: ARN of the Customer Managed Key (CMK) created in the KMS module.
variable "kms_key_arn" {
  description = "The ARN of the KMS CMK used for default bucket encryption."
  type        = string
}

