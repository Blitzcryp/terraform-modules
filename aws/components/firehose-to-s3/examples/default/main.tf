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

# Minimal, PCI-compliant usage: the component creates a CMK, a private encrypted
# delivery bucket, a KMS-encrypted error log group, a least-privilege delivery
# role and the Firehose stream — all wired together. Everything else is inherited
# from the secure defaults baked into the config object.
module "firehose_to_s3" {
  source = "../.."

  config = {
    name = "example-events"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "firehose_arn" {
  value = module.firehose_to_s3.manifest.firehose_arn
}

output "bucket_name" {
  value = module.firehose_to_s3.manifest.bucket_name
}
