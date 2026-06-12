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

# Minimal usage: subscribe an SQS queue to an existing SNS topic. The topic ARN
# and endpoint are owned elsewhere and passed in by reference.
module "sns_subscription" {
  source = "../.."

  config = {
    topic_arn = "arn:aws:sns:eu-central-1:111122223333:example-events"
    protocol  = "sqs"
    endpoint  = "arn:aws:sqs:eu-central-1:111122223333:example-queue"

    raw_message_delivery = true
  }
}

output "subscription_arn" {
  value = module.sns_subscription.manifest.arn
}
