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

# Standard record: an A record with a 300s TTL.
module "a_record" {
  source = "../.."

  config = {
    zone_id = "Z01234567ABCDEFGHIJK"
    name    = "app.example.com"
    type    = "A"
    records = ["203.0.113.10"]
  }
}

# Alias record: point the apex at an ALB (ttl/records omitted automatically).
module "alias_record" {
  source = "../.."

  config = {
    zone_id = "Z01234567ABCDEFGHIJK"
    name    = "example.com"
    type    = "A"
    alias = {
      name    = "dualstack.my-alb-1234567890.eu-central-1.elb.amazonaws.com"
      zone_id = "Z215JYRZR1TBD5" # eu-central-1 ALB hosted zone id
    }
  }
}

output "a_record_fqdn" {
  value = module.a_record.manifest.fqdn
}

output "alias_record_fqdn" {
  value = module.alias_record.manifest.fqdn
}
