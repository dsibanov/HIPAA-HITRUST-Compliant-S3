# ----------------------------------------------------------------------------------
# 1. DEDICATED LOGGING BUCKET (AUDIT CONTROL)
# ----------------------------------------------------------------------------------
# A separate, private bucket to store access logs for the data bucket.
resource "aws_s3_bucket" "logging_bucket" {
  bucket = "${var.project_name}-s3-access-logs-${var.environment}"
  acl    = "log-delivery-write" # Required ACL for AWS S3 logging service
  
  # Enforce Encryption on the logging bucket itself
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "S3-Access-Logs-${var.project_name}-${var.environment}"
    Project     = var.project_name
    Environment = var.environment
    Compliance  = "HIPAA-HITRUST-Audit"
  }
}

# Logging bucket retention policy (HIPAA/HITRUST long-term retention requirements)
resource "aws_s3_bucket_lifecycle_configuration" "logging_bucket_lifecycle" {
  bucket = aws_s3_bucket.logging_bucket.id
  rule {
    id     = "log_retention"
    status = "Enabled"
    expiration {
      days = var.logging_bucket_retention_days
    }
  }
}

# ----------------------------------------------------------------------------------
# 2. PHI DATA BUCKET (MAIN RESOURCE)
# ----------------------------------------------------------------------------------
resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.project_name}-phi-data-${var.environment}"
  
  # IMPORTANT: Set bucket ACL to private and control access via Bucket Policy and IAM only.
  acl    = "private" 

  tags = {
    Name        = "PHI-Data-${var.project_name}-${var.environment}"
    Project     = var.project_name
    Environment = var.environment
    Compliance  = "HIPAA-HITRUST"
  }
}

# ----------------------------------------------------------------------------------
# 3. COMPLIANCE ENFORCEMENT CONFIGURATIONS
# ----------------------------------------------------------------------------------

# A. BLOCK PUBLIC ACCESS (MANDATORY HIPAA/HITRUST ACCESS CONTROL)
# All four public access settings must be enabled to prevent misconfiguration.
resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket                  = aws_s3_bucket.data_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# B. VERSIONING (MANDATORY HIPAA/HITRUST INTEGRITY AND AVAILABILITY)
# Keeps every version of an object to aid recovery from accidental deletion or modification.
resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# C. ENCRYPTION AT REST (MANDATORY HIPAA/HITRUST TECHNICAL SAFEGUARD)
# Enforces the use of the Customer Managed KMS Key we defined.
resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.data_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = var.kms_key_arn
    }
  }
}

# D. S3 ACCESS LOGGING (MANDATORY HIPAA/HITRUST AUDIT CONTROL)
# Points the data bucket's logs to the dedicated logging bucket.
resource "aws_s3_bucket_logging_v2" "data_bucket_logging" {
  bucket = aws_s3_bucket.data_bucket.id
  target_bucket = aws_s3_bucket.logging_bucket.id
  # Prefix helps organize logs within the target bucket
  target_prefix = "data-bucket-logs/"

  # Dependency to ensure logging bucket configuration is done first
  depends_on = [
    aws_s3_bucket_public_access_block.block_public
  ]
}

# E. OBJECT LOCK (MANDATORY FOR DATA INTEGRITY/NON-REPUDIATION)
# Sets the S3 Object Lock configuration on the bucket. Must be configured at creation, 
# so we use `lifecycle_rule` to prevent object deletion for the specified period.
resource "aws_s3_bucket_object_lock_configuration" "object_lock" {
  count  = var.retention_period_days > 0 ? 1 : 0
  bucket = aws_s3_bucket.data_bucket.id
  rule {
    default_retention {
      mode = "GOVERNANCE" # Governance mode allows authorized users to bypass the lock (Auditability)
      days = var.retention_period_days
    }
  }
}


# ----------------------------------------------------------------------------------
# 4. BUCKET POLICY (SECURITY ENFORCEMENT)
# ----------------------------------------------------------------------------------

# Data Source to define the policy document with compliance guardrails.
data "aws_iam_policy_document" "compliant_bucket_policy" {
  # Statement 1: Enforcement of HTTPS/TLS (HIPAA/HITRUST Transmission Security)
  statement {
    sid       = "ForceTLSOnly"
    effect    = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:*"]
    resources = [
      aws_s3_bucket.data_bucket.arn,
      "${aws_s3_bucket.data_bucket.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# Resource to apply the policy to the data bucket
resource "aws_s3_bucket_policy" "compliant_policy" {
  bucket = aws_s3_bucket.data_bucket.id
  policy = data.aws_iam_policy_document.compliant_bucket_policy.json
}
