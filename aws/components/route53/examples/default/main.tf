terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
    }
  }
}

# Default working region.
provider "aws" {
  region = "eu-central-1"
}

# REQUIRED for PUBLIC zones: AWS only delivers Route53 query logs to a
# CloudWatch Logs group in us-east-1, so the component creates the log group
# (and its CMK) through this us-east-1-aliased provider.
provider "aws" {
  alias  = "use1"
  region = "us-east-1"
}

# Minimal, PCI-compliant usage: a public hosted zone with DNS query logging to a
# us-east-1 CMK-encrypted log group (365-day retention). Everything else is
# inherited from the secure defaults.
module "route53" {
  source = "../.."

  providers = {
    aws      = aws
    aws.use1 = aws.use1
  }

  config = {
    name = "example.com"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "zone_id" {
  value = module.route53.manifest.zone_id
}

output "name_servers" {
  value = module.route53.manifest.name_servers
}

output "query_log_group_name" {
  value = module.route53.manifest.query_log_group_name
}
