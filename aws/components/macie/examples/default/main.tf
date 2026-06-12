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

# Minimal, PCI-compliant usage: enables Macie with the fastest finding cadence
# for continuous S3 sensitive-data discovery. Everything else is inherited from
# the secure defaults.
module "macie" {
  source = "../.."

  config = {
    tags = {
      Environment = "example"
      Owner       = "security"
    }
  }
}

output "macie_account_id" {
  value = module.macie.manifest.macie_account_id
}
