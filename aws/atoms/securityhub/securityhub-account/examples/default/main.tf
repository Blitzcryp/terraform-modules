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

# Minimal, PCI-compliant usage: enables Security Hub with consolidated control
# findings, auto-enabled new controls, and subscriptions to CIS AWS Foundations
# and AWS Foundational Security Best Practices. Everything is inherited from the
# secure defaults baked into the config object.
module "securityhub_account" {
  source = "../.."

  config = {
    tags = {
      Environment = "example"
      Owner       = "security"
    }
  }
}

output "enabled_standards" {
  value = module.securityhub_account.manifest.enabled_standards
}
