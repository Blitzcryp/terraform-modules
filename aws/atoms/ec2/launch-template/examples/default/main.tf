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

# Minimal PCI-compliant usage: a launch template with IMDSv2 enforced, an
# encrypted gp3 root volume, and detailed monitoring on. Access is expected via
# SSM Session Manager (attach AmazonSSMManagedInstanceCore through the instance
# profile) — no SSH key pair is set (PCI DSS Req 8).
module "launch_template" {
  source = "../.."

  config = {
    name                   = "example-app"
    image_id               = "ami-0a1b2c3d4e5f60718"
    instance_type          = "t3.micro"
    vpc_security_group_ids = ["sg-0a1b2c3d4e5f60099"]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "manifest" {
  value = module.launch_template.manifest
}
