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

# Minimal usage: attach a managed policy to an existing group. The group is
# assumed to already exist (created by the iam-group atom or component).
module "iam_group_policy_attachment" {
  source = "../.."

  config = {
    group      = "example-developers"
    policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
  }
}

output "attachment_id" {
  value = module.iam_group_policy_attachment.manifest.id
}
