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

# Minimal, PCI-compliant usage: records ALL resource types (including global)
# to the supplied bucket via the supplied Config role. The bucket and role are
# owned elsewhere (e.g. the cspm component) and passed in by reference.
module "config_recorder" {
  source = "../.."

  config = {
    name           = "example-recorder"
    s3_bucket_name = "example-config-delivery-bucket"
    iam_role_arn   = "arn:aws:iam::111122223333:role/example-config-role"
    tags = {
      Environment = "example"
      Owner       = "security"
    }
  }
}

output "recorder_name" {
  value = module.config_recorder.manifest.recorder_name
}
