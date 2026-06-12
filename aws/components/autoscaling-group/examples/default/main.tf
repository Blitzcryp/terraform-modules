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

# Minimal PCI-compliant usage: an ASG of 2-4 private instances across two
# subnets, scaling from a launch template with IMDSv2 enforced and an encrypted
# root volume backed by a component-created KMS key. The instances share a
# security group (ingress only from the supplied app SG) and an instance profile
# granting SSM Session Manager access. No SSH key pair (PCI DSS Req 1/2/8).
module "autoscaling_group" {
  source = "../.."

  config = {
    name       = "example-app"
    image_id   = "ami-0a1b2c3d4e5f60718"
    vpc_id     = "vpc-0a1b2c3d4e5f60718"
    subnet_ids = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]

    allowed_security_group_ids = ["sg-0a1b2c3d4e5f60099"]

    # SSM Session Manager for access instead of SSH (PCI DSS Req 8).
    managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "manifest" {
  value = module.autoscaling_group.manifest
}
