# ----------------------------------------------------------------------------------
# DEPLOYMENT OUTPUTS
# These help users and auditors quickly locate the deployed resources.
# ----------------------------------------------------------------------------------

output "phi_data_bucket_name" {
  description = "The name of the HIPAA/HITRUST compliant S3 bucket for PHI data."
  value       = module.compliant_s3.data_bucket_id
}

output "phi_data_bucket_arn" {
  description = "The ARN of the HIPAA/HITRUST compliant S3 bucket for PHI data."
  value       = module.compliant_s3.data_bucket_arn
}

output "kms_key_arn" {
  description = "The ARN of the KMS Customer Managed Key used for S3 encryption."
  value       = module.compliant_kms.kms_key_arn
}

output "s3_access_logging_bucket_name" {
  description = "The name of the dedicated S3 bucket storing access logs for audit purposes."
  value       = module.compliant_s3.logging_bucket_id
}
