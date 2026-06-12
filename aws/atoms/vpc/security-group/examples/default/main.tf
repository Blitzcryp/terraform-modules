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

# Minimal, PCI-compliant usage: HTTPS allowed only from inside the VPC CIDR,
# egress restricted to HTTPS to the VPC CIDR. No public ingress, no implicit
# allow-all egress — every rule is explicit and documented (PCI DSS Req 1).
module "security_group" {
  source = "../.."

  config = {
    name        = "example-app-sg"
    vpc_id      = "vpc-12345678"
    description = "Example application security group"

    ingress_rules = [
      {
        description = "HTTPS from within the VPC"
        ip_protocol = "tcp"
        from_port   = 443
        to_port     = 443
        cidr_ipv4   = "10.0.0.0/16"
      },
    ]

    egress_rules = [
      {
        description = "HTTPS to within the VPC"
        ip_protocol = "tcp"
        from_port   = 443
        to_port     = 443
        cidr_ipv4   = "10.0.0.0/16"
      },
    ]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "security_group_id" {
  value = module.security_group.manifest.id
}
