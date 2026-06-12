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

# Minimal usage: wrap an existing IAM role name in an instance profile so EC2
# can assume it. The role is passed in by reference (atoms never create deps).
module "iam_instance_profile" {
  source = "../.."

  config = {
    name = "example-app-instance-profile"
    role = "example-ec2-app-role"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "instance_profile_arn" {
  value = module.iam_instance_profile.manifest.arn
}
