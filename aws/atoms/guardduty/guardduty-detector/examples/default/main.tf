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

# Minimal, PCI-compliant usage: enables GuardDuty with the fastest finding
# cadence and S3 + malware protection. Everything else is inherited from the
# secure defaults baked into the config object.
module "guardduty_detector" {
  source = "../.."

  config = {
    tags = {
      Environment = "example"
      Owner       = "security"
    }
  }
}

output "detector_id" {
  value = module.guardduty_detector.manifest.detector_id
}
