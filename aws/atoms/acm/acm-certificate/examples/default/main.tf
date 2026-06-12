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

# Minimal usage: a DNS-validated RSA_2048 certificate request. This atom only
# requests the certificate; publishing the DNS validation records and waiting for
# issuance is the caller's job (see components/acm for the full flow).
module "acm_certificate" {
  source = "../.."

  config = {
    domain_name               = "app.example.com"
    subject_alternative_names = ["www.app.example.com"]
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "certificate_arn" {
  value = module.acm_certificate.manifest.arn
}
