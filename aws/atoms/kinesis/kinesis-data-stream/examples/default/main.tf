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

# Minimal, PCI-compliant usage: KMS-encrypted with a customer-managed CMK,
# on-demand stream, 24h retention. Everything else is inherited from the secure
# defaults baked into the config object.
variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN to encrypt the stream."
  type        = string
  default     = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
}

module "kinesis_data_stream" {
  source = "../.."

  config = {
    name        = "example-events"
    kms_key_arn = var.kms_key_arn
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "stream_arn" {
  value = module.kinesis_data_stream.manifest.arn
}
