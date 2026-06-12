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

# Minimal PCI-compliant usage of the Vault capability: a dedicated CMK is
# created and used to encrypt two secrets, each with a 30-day recovery window.
# All security controls come from secure defaults.
#
# SECURITY: secret VALUES are never set here. After apply, populate the secret
# material out-of-band (a secrets source, CI/CD secret store, or a rotation
# Lambda) — never commit real material. Use <YOUR_SECRET_VALUE> placeholders in
# any tooling (PCI DSS Req 3.5 / Req 8).
module "vault" {
  source = "../.."

  config = {
    name_prefix = "emag/payments"

    secrets = {
      "db-password" = {
        description = "Payments DB credentials"
      }
      "api-token" = {
        description = "Third-party payment gateway token"
      }
    }

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "manifest" {
  value = module.vault.manifest
}
