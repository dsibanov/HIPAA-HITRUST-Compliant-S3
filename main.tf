
# ----------------------------------------------------------------------------------
# 1. TERRAFORM AND PROVIDER CONFIGURATION
# ----------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ----------------------------------------------------------------------------------
# 2. DATA SOURCES (Needed for KMS Key Policy)
# ----------------------------------------------------------------------------------

# Get the current AWS Account ID
data "aws_caller_identity" "current" {}

# Get the current AWS Region
data "aws_region" "current" {}

# ----------------------------------------------------------------------------------
# 3. KMS MODULE CALL (Encryption Key)
# ----------------------------------------------------------------------------------

module "compliant_kms" {
  source = "./modules/kms"

  project_name               = var.project_name
  environment                = var.environment
  kms_key_administrator_arns = var.kms_key_administrator_arns
  kms_key_user_arns          = var.kms_key_user_arns
}

# ----------------------------------------------------------------------------------
# 4. S3 COMPLIANT MODULE CALL (PHI Data Storage)
# ----------------------------------------------------------------------------------

module "compliant_s3" {
  source = "./modules/s3_compliant"

  project_name              = var.project_name
  environment               = var.environment
  aws_region                = var.aws_region
  retention_period_days     = var.retention_period_days
  logging_bucket_retention_days = var.logging_bucket_retention_days
  
  # Pass the ARN of the KMS key generated in the previous module
  kms_key_arn = module.compliant_kms.kms_key_arn
}
