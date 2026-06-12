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

# Minimal, PCI-compliant usage: rotation on, 30-day deletion window, least-privilege policy.
# Everything else is inherited from the secure defaults baked into the config object.
module "kms_key" {
  source = "../.."

  config = {
    description = "Example application data key"
    alias       = "example/app-data"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "key_arn" {
  value = module.kms_key.manifest.arn
}
