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

# Minimal usage: a rule that matches Security Hub findings on the default bus.
module "event_rule" {
  source = "../.."

  config = {
    name        = "example-securityhub-findings"
    description = "Route Security Hub findings"
    event_pattern = jsonencode({
      source      = ["aws.securityhub"]
      detail-type = ["Security Hub Findings - Imported"]
    })
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "rule_arn" {
  value = module.event_rule.manifest.arn
}
