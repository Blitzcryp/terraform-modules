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

# Minimal PCI-compliant usage: an encrypted gp3 data volume in one AZ. Attach it
# to an instance with an aws_volume_attachment in the caller's configuration.
module "ebs_volume" {
  source = "../.."

  config = {
    availability_zone = "eu-central-1a"
    size              = 20

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "manifest" {
  value = module.ebs_volume.manifest
}
