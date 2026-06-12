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

# Minimal, PCI-compliant usage: a private-tier network ACL. NACLs are stateless
# and default-deny, so every opening is explicit AND its return path is opened
# separately via the ephemeral port range. No rule reaches the public internet.
#
#   Ingress: allow VPC-internal HTTPS, plus ephemeral return ports from the VPC.
#   Egress:  allow HTTPS to the VPC, plus ephemeral return ports to the VPC.
#
# Anything not matched by a numbered rule is dropped (PCI DSS Req 1 — subnet
# defense-in-depth layered on top of security groups).
module "network_acl" {
  source = "../.."

  config = {
    vpc_id     = "vpc-12345678"
    name       = "example-private-nacl"
    subnet_ids = ["subnet-aaaa1111", "subnet-bbbb2222"]

    ingress_rules = [
      {
        rule_number = 100
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/16"
        from_port   = 443
        to_port     = 443
      },
      {
        # Return traffic for connections this tier initiates outbound.
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
        protocol    = "tcp"
        rule_action = "allow"
        cidr_block  = "10.0.0.0/16"
        from_port   = 443
        to_port     = 443
      },
      {
        # Return traffic for connections this tier serves inbound.
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
    }
  }
}

output "network_acl_id" {
  value = module.network_acl.manifest.id
}
