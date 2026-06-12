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

# Recommended PRIVATE-TIER baseline (PCI DSS Req 1, defense-in-depth on top of
# security groups). NACLs are stateless and default-deny: allow VPC-internal
# traffic plus the ephemeral return ports, and let everything else fall through
# to the implicit deny. No rule touches the public internet, so no escape hatch
# is needed.
module "private_nacl" {
  source = "../.."

  config = {
    name       = "private-tier"
    vpc_id     = "vpc-12345678"
    subnet_ids = ["subnet-aaaa1111", "subnet-bbbb2222"]

    ingress_rules = [
      {
        rule_number = 100
        protocol    = "-1" # all VPC-internal traffic
        rule_action = "allow"
        cidr_block  = "10.0.0.0/16"
      },
      {
        # Ephemeral return ports for connections this tier initiates to
        # VPC-internal endpoints. Scoped to the VPC CIDR — no public exposure.
        rule_number = 110
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/16"
        from_port   = 1024
        to_port     = 65535
      },
    ]

    egress_rules = [
      {
        rule_number = 100
        protocol    = "-1"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/16"
      },
      {
        # Ephemeral return ports for inbound connections this tier serves to
        # VPC-internal clients. Scoped to the VPC CIDR — no public exposure.
        rule_number = 110
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/16"
        from_port   = 1024
        to_port     = 65535
      },
    ]

    tags = {
      Environment = "example"
      Owner       = "platform"
      Tier        = "private"
    }
  }
}

output "network_acl_id" {
  value = module.private_nacl.manifest.network_acl_id
}
