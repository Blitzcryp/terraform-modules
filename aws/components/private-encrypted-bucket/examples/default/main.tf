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

# Minimal PCI-compliant usage: a fully locked-down, KMS-encrypted, versioned,
# access-logged bucket. All security controls come from secure defaults.
module "private_encrypted_bucket" {
  source = "../.."

  config = {
    bucket = "example-cardholder-data"
  }
}

output "manifest" {
  value = module.private_encrypted_bucket.manifest
}
