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

# Minimal, PCI-compliant usage: encryption at rest via a CMK, a dead-letter
# queue, and the default policy denying non-TLS access. If kms_key_arn were
# omitted, the module would still encrypt the queue using SSE-SQS.
module "sqs_queue" {
  source = "../.."

  config = {
    name = "example-jobs"

    # Replace with a real CMK ARN. Omitting it falls back to SSE-SQS (still encrypted).
    kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/00000000-0000-0000-0000-000000000000"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "queue_arn" {
  value = module.sqs_queue.manifest.arn
}

output "dlq_arn" {
  value = module.sqs_queue.manifest.dlq_arn
}
