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

# Minimal, PCI-compliant usage: explicit trust policy, 1h session cap,
# force_detach on, least-privilege inline policy (scoped, not "*"/"*").
module "iam_role" {
  source = "../.."

  config = {
    name        = "example-ec2-app-role"
    description = "Example application role assumable by EC2"

    # Sample EC2 assume-role (trust) policy — only the EC2 service may assume it.
    assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect    = "Allow"
          Principal = { Service = "ec2.amazonaws.com" }
          Action    = "sts:AssumeRole"
        }
      ]
    })

    inline_policies = {
      read-app-config = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect   = "Allow"
            Action   = ["ssm:GetParameter"]
            Resource = ["arn:aws:ssm:eu-central-1:123456789012:parameter/example/app/*"]
          }
        ]
      })
    }

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "role_arn" {
  value = module.iam_role.manifest.arn
}
