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

# A single NFS mount endpoint for an existing EFS file system in one subnet,
# reachable only via the supplied NFS-only security group (no public access).
module "efs_mount_target" {
  source = "../.."

  config = {
    file_system_id  = "fs-0a1b2c3d4e5f60718"
    subnet_id       = "subnet-0a1b2c3d4e5f60001"
    security_groups = ["sg-0a1b2c3d4e5f60099"]
  }
}

output "manifest" {
  value = module.efs_mount_target.manifest
}
