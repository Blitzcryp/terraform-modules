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

# Minimal, PCI-compliant usage: 14-char minimum, full character complexity,
# 4-cycle reuse prevention and 90-day rotation. The account password policy is
# an account-level singleton, so no inputs are required — everything is
# inherited from the secure defaults baked into the config object.
module "account_password_policy" {
  source = "../.."

  config = {}
}

output "minimum_password_length" {
  value = module.account_password_policy.manifest.minimum_password_length
}
