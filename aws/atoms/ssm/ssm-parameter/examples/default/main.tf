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

# A CMK to encrypt the SecureString at rest (PCI DSS Req 3).
module "param_key" {
  source = "../../../../kms/kms-key"

  config = {
    description = "CMK for the example SSM parameter"
    alias       = "ssm/example-app"
  }
}

# Minimal, PCI-compliant usage: SecureString encrypted with a CMK.
# SECURITY: the value is NEVER a real secret in source control. Use a
# <YOUR_PARAMETER_VALUE> placeholder and supply the real value out-of-band
# (CI/CD secret store) (PCI DSS Req 3 / Req 8).
module "parameter" {
  source = "../.."

  config = {
    name        = "/example-app/db-password"
    value       = "<YOUR_PARAMETER_VALUE>"
    kms_key_arn = module.param_key.manifest.arn
    description = "Example application DB password"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "manifest" {
  value = module.parameter.manifest
}
