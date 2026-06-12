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

# Minimal, PCI-compliant usage: MFA ON with TOTP, 14-char complex passwords,
# advanced security ENFORCED, email recovery. Everything is inherited from the
# secure defaults baked into the config object.
module "user_pool" {
  source = "../.."

  config = {
    name = "example-auth-pool"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "user_pool_arn" {
  value = module.user_pool.manifest.arn
}
