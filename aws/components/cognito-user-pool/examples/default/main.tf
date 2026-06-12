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

# Minimal, PCI-compliant usage: a hardened user pool (MFA ON + TOTP, advanced
# security ENFORCED, 14-char complex passwords), a confidential app client
# (generated secret, authorization-code OAuth only, SRP auth) and a hosted-UI
# domain. Everything inherits the secure defaults baked into the atoms.
module "auth" {
  source = "../.."

  config = {
    name = "example-auth"
    callback_urls = [
      "https://app.example.com/oauth2/callback",
    ]
    domain = "example-auth-emag"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "user_pool_id" {
  value = module.auth.manifest.user_pool_id
}

# client_secret is sensitive; surfaced here only to demonstrate the manifest.
output "client_id" {
  value     = module.auth.manifest.client_id
  sensitive = true
}
