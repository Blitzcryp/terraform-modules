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

# Minimal, PCI-compliant usage: creates a private domain security group (HTTPS
# 443 only, ingress from the supplied client SG), an OpenSearch- and
# CloudWatch-Logs-authorised CMK, a CMK-encrypted audit/slow-log group with
# 365-day retention, and a VPC-placed OpenSearch domain with encryption at rest
# (CMK), node-to-node encryption, enforced HTTPS/TLS 1.2 and fine-grained access
# control. Subnet/SG IDs below are placeholders.
module "opensearch" {
  source = "../.."

  config = {
    name       = "example-search"
    vpc_id     = "vpc-0123456789abcdef0"
    subnet_ids = ["subnet-0aaa1111bbbb2222c", "subnet-0ddd3333eeee4444f"]

    # Admit only this client security group on HTTPS (443).
    allowed_security_group_ids = ["sg-0clientaaaa1111bb"]
  }
}

output "domain_arn" {
  value = module.opensearch.manifest.domain_arn
}

output "endpoint" {
  value = module.opensearch.manifest.endpoint
}

output "security_group_id" {
  value = module.opensearch.manifest.security_group_id
}
