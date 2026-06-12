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

# Minimal, PCI-compliant usage: server-side encryption with a customer-managed
# CMK, KMS-encrypted S3 delivery and CloudWatch error logging. The bucket, role
# and KMS key are inputs (this atom never creates them) — in real use they come
# from a component such as `firehose-to-s3`.
variable "kms_key_arn" {
  description = "Customer-managed KMS key ARN for SSE and S3 delivery encryption."
  type        = string
  default     = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
}

variable "bucket_arn" {
  description = "Destination S3 bucket ARN."
  type        = string
  default     = "arn:aws:s3:::example-firehose-delivery"
}

variable "role_arn" {
  description = "Firehose delivery IAM role ARN."
  type        = string
  default     = "arn:aws:iam::111122223333:role/example-firehose-role"
}

module "firehose_delivery_stream" {
  source = "../.."

  config = {
    name        = "example-delivery"
    bucket_arn  = var.bucket_arn
    role_arn    = var.role_arn
    kms_key_arn = var.kms_key_arn

    prefix                    = "data/"
    cloudwatch_log_group_name = "/aws/kinesisfirehose/example-delivery"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "firehose_arn" {
  value = module.firehose_delivery_stream.manifest.arn
}
