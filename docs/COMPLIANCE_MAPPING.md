HIPAA / HITRUST Compliance Mapping: S3 & KMS Infrastructure

This document maps the configurations implemented in the Infrastructure-as-Code (Terraform) to specific security requirements mandated by the HIPAA Security Rule and reinforced by the HITRUST Common Security Framework (CSF).

1. Encryption and Key Management (Technical Safeguards)

Requirement

HIPAA / HITRUST Control

Implementation

Terraform Component

Data Encryption at Rest

HIPAA 164.312(a)(2)(iv) 
 HITRUST 09.ac

All PHI stored in the S3 bucket must be encrypted using a dedicated, rotating Customer Managed Key (CMK).

modules/s3_compliant/s3.tf: aws_s3_bucket_server_side_encryption_configuration enforces aws:kms using kms_master_key_id.

Key Access Control

HIPAA 164.306(a) 
 HITRUST 09.aa

Key usage and management is strictly limited to authorized IAM users/roles defined outside of the data access path.

modules/kms/kms.tf: The KMS Key Policy uses kms_key_administrator_arns and kms_key_user_arns variables to explicitly define who can administer or use the key.

Key Rotation

HITRUST 09.ac.2

The encryption key is set to automatically rotate annually to minimize risk exposure.

modules/kms/kms.tf: aws_kms_key resource sets key_usage = "ENCRYPT_DECRYPT" and deletion_window_in_days = 30 and enable_key_rotation = true.

2. Access Control (Technical and Administrative Safeguards)

Requirement

HIPAA / HITRUST Control

Implementation

Terraform Component

Public Access Prevention

HIPAA 164.312(a)(1) 
 HITRUST 07.c

Absolute denial of public read/write access to the PHI bucket, regardless of future policy changes.

modules/s3_compliant/s3.tf: aws_s3_bucket_public_access_block resource sets all four public access prevention flags to true.

Principle of Least Privilege

HIPAA 164.308(a)(4)(ii)(B) 
 HITRUST 09.a

Application roles are granted only the necessary s3:GetObject and kms:Decrypt/kms:GenerateDataKey permissions.

iam.tf: aws_iam_policy.phi_data_access_policy explicitly lists minimal s3: and kms: actions.

Transmission Security

HIPAA 164.312(e)(1) 
 HITRUST 10.g

All access to the S3 bucket must be over encrypted channels (HTTPS/TLS).

modules/s3_compliant/s3.tf: Bucket Policy Statement ForceTLSOnly denies access where the condition aws:SecureTransport is false.

3. Audit, Integrity, and Availability (Administrative & Technical Safeguards)

Requirement

HIPAA / HITRUST Control

Implementation

Terraform Component

Audit Trails/Activity Logs

HIPAA 164.312(b) 
 HITRUST 12.i

All read/write/delete activities on the PHI bucket are logged to a separate, restricted logging bucket.

modules/s3_compliant/s3.tf: aws_s3_bucket_logging_v2 points the PHI bucket to a dedicated aws_s3_bucket.logging_bucket with restricted ACL.

Data Integrity / Non-repudiation

HIPAA 164.312(c)(1) 
 HITRUST 08.d

Data deletion or modification is prevented for a set, minimum retention period.

modules/s3_compliant/s3.tf: aws_s3_bucket_object_lock_configuration enforces Governance Mode retention for var.retention_period_days.

Data Backup / Contingency Plan

HIPAA 164.308(a)(7)(ii)(A) 
 HITRUST 05.c

Maintains prior versions of data for recovery from accidental deletion or corruption.

modules/s3_compliant/s3.tf: aws_s3_bucket_versioning ensures versioning status is set to Enabled.
