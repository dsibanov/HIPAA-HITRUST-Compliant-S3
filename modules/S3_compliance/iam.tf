# ----------------------------------------------------------------------------------
# IAM CONFIGURATION FOR PHI ACCESS (HIPAA/HITRUST Access Control)
# ----------------------------------------------------------------------------------

# 1. IAM POLICY: Data Access Policy
# This policy defines the *minimal* required permissions for an application
# or service that needs to interact with the PHI data in the S3 bucket.
data "aws_iam_policy_document" "phi_data_access" {
  # Statement A: Read/Write Access to the S3 Objects
  statement {
    sid       = "AllowS3DataRW"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
    resources = [
      module.compliant_s3.data_bucket_arn,
      "${module.compliant_s3.data_bucket_arn}/*",
    ]
  }

  # Statement B: KMS Usage Permission (Decryption/Encryption)
  # This is crucial: the entity must have permission to use the KMS key
  # for the S3 operations to succeed. This maps directly to a HIPAA control.
  statement {
    sid       = "AllowKMSUsage"
    effect    = "Allow"
    actions   = ["kms:Decrypt", "kms:GenerateDataKey"]
    resources = [module.compliant_kms.kms_key_arn]
  }
}

# Resource: IAM Managed Policy
# This managed policy is what we will attach to the final role.
resource "aws_iam_policy" "phi_data_access_policy" {
  name        = "${var.project_name}-${var.environment}-PhiDataAccessPolicy"
  description = "Minimal permissions for application access to the HIPAA/HITRUST S3 bucket."
  policy      = data.aws_iam_policy_document.phi_data_access.json
}

# 2. IAM ROLE: Application Role (Example User)
# This role is assumed by an application (e.g., Lambda function, EC2 instance)
# to perform operations on the PHI data bucket.
resource "aws_iam_role" "application_role" {
  name               = "${var.project_name}-${var.environment}-AppRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        # Best practice is to restrict Principal to a specific service or account
        Principal = {
          Service = "lambda.amazonaws.com" # Example: Assuming a serverless application
        }
      },
    ]
  })
  tags = {
    Project     = var.project_name
    Environment = var.environment
    Compliance  = "HIPAA-HITRUST-Data-User"
  }
}

# Attach the policy to the application role
resource "aws_iam_role_policy_attachment" "app_role_data_access" {
  role       = aws_iam_role.application_role.name
  policy_arn = aws_iam_policy.phi_data_access_policy.arn
}

# 3. IAM ROLE: Security Administrator Role (Example Admin)
# This role is used by auditors or security teams and requires broader permissions
# to manage the bucket configuration (but not necessarily all data).
resource "aws_iam_role" "admin_role" {
  name               = "${var.project_name}-${var.environment}-AdminRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        # Example: Allowing specific accounts or federated users
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      },
    ]
  })
  tags = {
    Project     = var.project_name
    Environment = var.environment
    Compliance  = "HIPAA-HITRUST-Admin"
  }
}

# Attach the S3 Read-Only and CloudTrail-Read-Only policies for auditing/monitoring
resource "aws_iam_role_policy_attachment" "admin_s3_read" {
  role       = aws_iam_role.admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "admin_cloudtrail_read" {
  role       = aws_iam_role.admin_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudTrailReadOnlyAccess"
}

