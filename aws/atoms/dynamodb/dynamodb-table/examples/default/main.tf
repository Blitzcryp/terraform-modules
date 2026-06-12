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

# A KMS key to encrypt the table at rest (PCI DSS Req 3). In production this is
# usually a shared/created CMK; here we make one inline for a runnable example.
module "table_key" {
  source = "../../../../kms/kms-key"

  config = {
    description = "CMK for the example DynamoDB table"
    alias       = "dynamodb/example-orders"
  }
}

# Minimal, PCI-compliant usage: CMK SSE, point-in-time recovery on, deletion
# protection on — all inherited from the secure defaults.
module "table" {
  source = "../.."

  config = {
    name     = "example-orders"
    hash_key = "order_id"

    attributes = [
      { name = "order_id", type = "S" },
    ]

    kms_key_arn = module.table_key.manifest.arn

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "manifest" {
  value = module.table.manifest
}
