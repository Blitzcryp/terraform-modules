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

# Mixed usage: an apex alias record pointing at an ALB, plus a standard CNAME.
module "dns_record" {
  source = "../.."

  config = {
    zone_id = "Z01234567ABCDEFGHIJK"
    records = [
      {
        name = "example.com"
        type = "A"
        alias = {
          name    = "dualstack.my-alb-1234567890.eu-central-1.elb.amazonaws.com"
          zone_id = "Z215JYRZR1TBD5" # eu-central-1 ALB hosted zone id
        }
      },
      {
        name   = "docs.example.com"
        type   = "CNAME"
        values = ["my-docs-site.example.net"]
      },
    ]
    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "record_fqdns" {
  value = module.dns_record.manifest.record_fqdns
}
