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

# Minimal PCI-compliant usage: encryption at rest on (AWS-managed EFS CMK) and a
# file-system policy that denies any non-TLS access. Everything else inherits the
# secure defaults baked into the config object.
module "efs_file_system" {
  source = "../.."

  config = {
    name = "example-shared-fs"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "manifest" {
  value = module.efs_file_system.manifest
}
