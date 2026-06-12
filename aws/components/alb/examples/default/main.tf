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

# Minimal, PCI-compliant usage: an INTERNAL ALB with a dedicated security group
# (VPC-only ingress), a default HTTPS:443 target group, an HTTPS:443 listener,
# an HTTP:80 -> HTTPS redirect, and a dedicated S3 access-log bucket. Everything
# else is inherited from the secure defaults baked into the config object.
module "alb" {
  source = "../.."

  config = {
    name            = "example-alb"
    vpc_id          = "vpc-0123456789abcdef0"
    subnet_ids      = ["subnet-0aaa1111bbbb2222c", "subnet-0ddd3333eeee4444f"]
    certificate_arn = "arn:aws:acm:eu-central-1:111122223333:certificate/abcd1234-ab12-cd34-ef56-abcdef123456"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "alb_dns_name" {
  value = module.alb.manifest.alb_dns_name
}

output "access_logs_bucket" {
  value = module.alb.manifest.access_logs_bucket
}
