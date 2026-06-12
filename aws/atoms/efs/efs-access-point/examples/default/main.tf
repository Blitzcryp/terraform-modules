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

# An access point that pins a non-root POSIX identity and a jailed root directory
# for an application (least-privilege access to the shared file system).
module "efs_access_point" {
  source = "../.."

  config = {
    file_system_id = "fs-0a1b2c3d4e5f60718"

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

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "manifest" {
  value = module.efs_access_point.manifest
}
