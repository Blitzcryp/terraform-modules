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

# Minimal, PCI-compliant usage: a private S3 origin fronted via an OAC, TLS 1.2+,
# redirect-to-https, with a dedicated access-log bucket. No aliases, so the
# default *.cloudfront.net certificate is used (an ACM cert in us-east-1 would be
# REQUIRED to attach custom aliases).
module "cloudfront" {
  source = "../.."

  config = {
    name                  = "example-cdn"
    s3_origin_domain_name = "example-bucket.s3.eu-central-1.amazonaws.com"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "distribution_domain_name" {
  value = module.cloudfront.manifest.domain_name
}

output "oac_id" {
  value = module.cloudfront.manifest.oac_id
}

output "log_bucket" {
  value = module.cloudfront.manifest.log_bucket
}
