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

# Minimal, PCI-compliant usage: CMK-encrypted secret with a 30-day recovery
# window. The CMK ARN is supplied by the caller (an atom never creates its own
# dependencies). The secret VALUE is never set here — it is populated
# out-of-band by a secrets source or a rotation Lambda (PCI DSS Req 3.5 / 8).
# Use a <YOUR_SECRET_VALUE> placeholder workflow; never commit real material.
module "secret" {
  source = "../.."

  config = {
    name        = "example/app/db-password"
    description = "Example application DB credentials"
    kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "secret_arn" {
  value = module.secret.manifest.secret_arn
}
