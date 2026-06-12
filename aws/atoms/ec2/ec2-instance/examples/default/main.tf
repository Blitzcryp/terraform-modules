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

# Minimal PCI-compliant usage: a private instance with IMDSv2 enforced, an
# encrypted gp3 root volume, detailed monitoring on, and NO public IP. Access is
# expected via SSM Session Manager (attach AmazonSSMManagedInstanceCore through
# the instance profile) — no SSH key pair is set (PCI DSS Req 8).
module "ec2_instance" {
  source = "../.."

  config = {
    ami                    = "ami-0a1b2c3d4e5f60718"
    instance_type          = "t3.micro"
    subnet_id              = "subnet-0a1b2c3d4e5f60001"
    vpc_security_group_ids = ["sg-0a1b2c3d4e5f60099"]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "manifest" {
  value = module.ec2_instance.manifest
}
