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

# Minimal, PCI-compliant usage: enables the full posture baseline — Security
# Hub (CIS + FSBP standards), AWS Config (recording all resources to a private,
# CMK-encrypted delivery bucket with a least-privilege service role), GuardDuty
# (S3 + malware protection) and Inspector v2 (ECR/EC2/Lambda scanning). The
# component owns a compliant CMK because no kms_key_arn is supplied.
module "cspm" {
  source = "../.."

  config = {
    name_prefix = "example"
  }
}

output "config_bucket_arn" {
  value = module.cspm.manifest.config_bucket_arn
}

output "guardduty_detector_id" {
  value = module.cspm.manifest.guardduty_detector_id
}
