terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

# Minimal, PCI-compliant usage: a multi-region, log-file-validated, KMS-encrypted
# trail with its own log store. The component creates the CMK (authorised for
# CloudTrail + CloudWatch Logs), the immutable S3 log bucket (with the required
# CloudTrail bucket policy), the encrypted CloudWatch log group with 365-day
# retention, and the least-privilege CloudTrail->CWL delivery role.
module "cloudtrail" {
  source = "../.."

  config = {
    name = "example-audit"
  }
}

output "trail_arn" {
  value = module.cloudtrail.manifest.trail_arn
}

output "bucket_name" {
  value = module.cloudtrail.manifest.bucket_name
}

output "log_group_name" {
  value = module.cloudtrail.manifest.log_group_name
}
