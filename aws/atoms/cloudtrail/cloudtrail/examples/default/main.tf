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
# trail. The S3 bucket and KMS key are owned by higher layers and passed in by
# name/ARN (fake values below). Everything else inherits the secure defaults.
module "cloudtrail" {
  source = "../.."

  config = {
    name           = "example-org-trail"
    s3_bucket_name = "example-cloudtrail-logs-111122223333"
    kms_key_arn    = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "trail_arn" {
  value = module.cloudtrail.manifest.arn
}
