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

# Minimal, PCI-compliant usage: applies an account-wide IAM password policy with
# a 14-char minimum, full character complexity, 4-cycle reuse prevention and
# 90-day rotation. Everything is inherited from the secure defaults baked into
# the config object.
module "account_baseline" {
  source = "../.."

  config = {}
}

output "password_policy_min_length" {
  value = module.account_baseline.manifest.password_policy_min_length
}
