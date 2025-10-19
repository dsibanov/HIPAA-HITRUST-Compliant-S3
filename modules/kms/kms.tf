
# ----------------------------------------------------------------------------------
# KMS KEY DEFINITION (ENCRYPTION AT REST)
# ----------------------------------------------------------------------------------

# Resource: aws_kms_key
# This CMK is used as the default encryption key for the S3 bucket storing PHI.
# Using a CMK (instead of AWS managed keys) provides auditability and explicit control over access.
resource "aws_kms_key" "s3_data_key" {
  description             = "KMS CMK for encrypting HIPAA/HITRUST S3 bucket data (${var.project_name}-${var.environment})"
  deletion_window_in_days = 7
  # Mandatory: KMS Key rotation is an important security control (HITRUST 09.ac).
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.key_policy.json
  tags = {
    Name        = "${var.project_name}-s3-data-key-${var.environment}"
    Project     = var.project_name
    Environment = var.environment
    Compliance  = "HIPAA-HITRUST"
  }
}

# ----------------------------------------------------------------------------------
# KMS KEY POLICY DOCUMENT
# ----------------------------------------------------------------------------------

# Data Source: aws_iam_policy_document
# This policy defines who can administer and use the key. It's the core of the
# "Least Privilege" access control for the encryption mechanism.
data "aws_iam_policy_document" "key_policy" {
  # 1. Statement for the AWS Account Root (Admin Fallback)
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # 2. Statement for KMS Key Administrators (As defined in variables.tf)
  statement {
    sid    = "Allow Administrators to Manage the Key"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = var.kms_key_administrator_arns
    }
    # Actions for key management (e.g., enable, disable, update)
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
  }

  # 3. Statement for KMS Key Users (Application Roles - Least Privilege)
  statement {
    sid    = "Allow Users to Encrypt and Decrypt"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = var.kms_key_user_arns
    }
    # Restricted actions for data usage only
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

# ----------------------------------------------------------------------------------
# DATA SOURCES
# ----------------------------------------------------------------------------------
# We need these to construct ARNs and the key policy.
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
