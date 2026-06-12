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

# Minimal usage: block apply until the referenced certificate is ISSUED, after
# the validation records (by FQDN) have been published. The certificate ARN and
# FQDNs normally come from the acm-certificate and route53-record atoms — see
# components/acm for the wired-up flow.
module "acm_certificate_validation" {
  source = "../.."

  config = {
    certificate_arn = "arn:aws:acm:eu-central-1:111122223333:certificate/00000000-0000-0000-0000-000000000000"
    validation_record_fqdns = [
      "_a79865eb4cd1a6ab990a45779b4e0b96.app.example.com",
    ]
  }
}

output "validated_certificate_arn" {
  value = module.acm_certificate_validation.manifest.certificate_arn
}
