# ----------------------------------------------------------------------------------
# MODULE OUTPUTS
# These values are exposed to the root configuration (main.tf).
# ----------------------------------------------------------------------------------

output "kms_key_arn" {
  description = "The ARN of the KMS Customer Managed Key."
  value       = aws_kms_key.s3_data_key.arn
}

output "kms_key_id" {
  description = "The ID of the KMS Customer Managed Key."
  value       = aws_kms_key.s3_data_key.id
}
