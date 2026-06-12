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

# Minimal usage: creates an IAM group. Attach policies to the group and add
# users via the iam-group-policy-attachment / iam-group-membership atoms (or the
# iam-group component which composes them).
module "iam_group" {
  source = "../.."

  config = {
    name = "example-developers"
  }
}

output "group_arn" {
  value = module.iam_group.manifest.arn
}
