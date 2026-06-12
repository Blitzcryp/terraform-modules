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

# Minimal PCI-compliant usage: an encrypted, shared EFS file system across two
# private subnets. Storage is encrypted with a component-created KMS key, a
# file-system policy denies any non-TLS access, one mount target is created per
# subnet, and the mount-target security group only lets the supplied app
# security group reach NFS port 2049 — no public ingress.
module "efs" {
  source = "../.."

  config = {
    name       = "example-shared"
    vpc_id     = "vpc-0a1b2c3d4e5f60718"
    subnet_ids = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]

    allowed_security_group_ids = ["sg-0a1b2c3d4e5f60099"]

    access_points = {
      app = {
        posix_user = {
          uid = 1000
          gid = 1000
        }
        root_directory = {
          path = "/app-data"
          creation_info = {
            owner_uid   = 1000
            owner_gid   = 1000
            permissions = "0750"
          }
        }
      }
    }
  }
}

output "manifest" {
  value = module.efs.manifest
}
