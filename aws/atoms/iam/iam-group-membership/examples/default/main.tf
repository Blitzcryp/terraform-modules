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

# Minimal usage: declare the full membership of a group. The group and users are
# assumed to already exist (created by the iam-group / iam-user atoms or
# components). This resource owns the group's membership exclusively.
module "iam_group_membership" {
  source = "../.."

  config = {
    name  = "developers-membership"
    group = "example-developers"
    users = ["example-app-user", "example-second-user"]
  }
}

output "members" {
  value = module.iam_group_membership.manifest.users
}
