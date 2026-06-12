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

# Minimal, PCI-compliant usage: SSE-KMS on, versioning on, public access blocked,
# ACLs disabled, TLS-only bucket policy.
module "s3_bucket" {
  source = "../.."

  config = {
    bucket = "emag-example-pci-bucket"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "bucket_arn" {
  value = module.s3_bucket.manifest.arn
}
