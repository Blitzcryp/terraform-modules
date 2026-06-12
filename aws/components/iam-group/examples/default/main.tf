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

# Minimal, PCI-compliant usage: an IAM group with a least-privilege managed
# policy attached and a defined set of members. Permissions and membership are
# managed group-centrically (PCI DSS Req 7), not per-user. The referenced users
# are created separately via the iam-user component.
module "iam_group" {
  source = "../.."

  config = {
    name = "example-readonly-developers"

    managed_policy_arns = [
      "arn:aws:iam::aws:policy/ReadOnlyAccess",
    ]

    users = [
      "example-human-user",
    ]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "group_arn" {
  value = module.iam_group.manifest.group_arn
}

output "members" {
  value = module.iam_group.manifest.members
}
