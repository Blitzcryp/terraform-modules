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

# Minimal, PCI-compliant usage: a public hosted zone with DNS query logging
# enabled (PCI DSS Req 10). The CloudWatch Logs group for a public zone must
# live in us-east-1. Everything else inherits the secure defaults.
module "route53_zone" {
  source = "../.."

  config = {
    name = "example.emag.internal"
    # Fake us-east-1 CloudWatch Logs group ARN for the example.
    query_log_destination_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/example.emag.internal:*"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "zone_name_servers" {
  value = module.route53_zone.manifest.name_servers
}
