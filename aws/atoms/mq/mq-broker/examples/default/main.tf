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

# Minimal, PCI-compliant usage: private broker, customer-managed CMK at rest,
# general + audit logging. Subnet / SG / KMS values are placeholders for the example.
#
# SECURITY (PCI DSS Req 8): the broker user password below is a PLACEHOLDER, not a
# real credential. In real usage source it from AWS Secrets Manager / SSM, e.g.:
#   password = data.aws_secretsmanager_secret_version.mq.secret_string
# NEVER commit a real password to source control.
module "mq_broker" {
  source = "../.."

  config = {
    broker_name = "example-broker"

    subnet_ids      = ["subnet-0aaaaaaaaaaaaaaa1", "subnet-0aaaaaaaaaaaaaaa2"]
    security_groups = ["sg-0aaaaaaaaaaaaaaa1"]

    kms_key_arn = "arn:aws:kms:eu-central-1:000000000000:key/00000000-0000-0000-0000-000000000000"

    users = [
      {
        username       = "app-service"
        password       = "<YOUR_BROKER_PASSWORD>" # placeholder — inject from a secrets manager
        console_access = false
      },
    ]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "broker_arn" {
  value = module.mq_broker.manifest.arn
}
