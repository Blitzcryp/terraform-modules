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

# Minimal PCI-compliant usage: a dedicated CMK is created and used to encrypt a
# set of SecureString parameters. All security controls come from secure
# defaults.
#
# SECURITY: parameter VALUES are never real secrets in source control. Use
# <YOUR_PARAMETER_VALUE> placeholders and supply real values out-of-band (CI/CD
# secret store) (PCI DSS Req 3 / Req 8).
module "app_params" {
  source = "../.."

  config = {
    name_prefix = "/emag/payments"

    parameters = {
      "db-password" = {
        value       = "<YOUR_PARAMETER_VALUE>"
        description = "Payments DB password"
      }
      "api-token" = {
        value       = "<YOUR_PARAMETER_VALUE>"
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
  value = module.app_params.manifest
}
