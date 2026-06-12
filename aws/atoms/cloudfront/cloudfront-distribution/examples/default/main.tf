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

# Minimal, PCI-compliant usage: a single private S3 origin fronted via OAC,
# TLS 1.2+ to viewers, redirect-to-https, default CloudFront certificate.
# (No aliases, so the default *.cloudfront.net cert is fine; an ACM cert in
# us-east-1 would be required to attach custom aliases.)
module "cloudfront_distribution" {
  source = "../.."

  config = {
    comment = "Example distribution for a private S3 origin"

    origins = [
      {
        domain_name              = "example-bucket.s3.eu-central-1.amazonaws.com"
        origin_id                = "s3-example"
        origin_access_control_id = "E1EXAMPLEOAC1" # from the cloudfront-origin-access-control atom
        s3_origin_config         = {}              # OAC origins still take an (empty) s3_origin_config
      }
    ]

    default_cache_behavior = {
      target_origin_id = "s3-example"
      cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6" # AWS managed CachingOptimized
    }

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "distribution_domain_name" {
  value = module.cloudfront_distribution.manifest.domain_name
}
