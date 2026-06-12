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

# Minimal usage: a DNS-validated, ISSUED certificate for app.example.com plus a
# www SAN. The validation CNAMEs are created in the supplied hosted zone and the
# apply blocks until ACM reports the certificate as ISSUED.
module "acm" {
  source = "../.."

  config = {
    domain_name               = "app.example.com"
    subject_alternative_names = ["www.app.example.com"]
    hosted_zone_id            = "Z01234567ABCDEFGHIJK"
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "certificate_arn" {
  value = module.acm.manifest.certificate_arn
}
