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

# Minimal, secure usage: SigV4 signing, always sign, for an S3 origin.
module "oac" {
  source = "../.."

  config = {
    name        = "example-s3-oac"
    description = "OAC for example private S3 origin"
  }
}

output "oac_id" {
  value = module.oac.manifest.id
}
