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

# SECURITY (PCI DSS Req 8): broker user passwords MUST be sourced from a secrets
# manager (AWS Secrets Manager / SSM SecureString / a Vault-backed tfvars), NOT
# hardcoded or committed to source control. The placeholder below is NOT a real
# credential — replace it with a secrets-manager lookup before applying. Example:
#   password = data.aws_secretsmanager_secret_version.mq_admin.secret_string
#
# Minimal, PCI-compliant usage: a private broker SG (ActiveMQ TLS ports only,
# ingress from the supplied client SG), a CMK created for at-rest encryption, and
# a non-public ACTIVE_STANDBY_MULTI_AZ ActiveMQ broker with general + audit logs.
# Subnet/SG IDs below are placeholders.
module "mq" {
  source = "../.."

  config = {
    broker_name = "example-mq"
    vpc_id      = "vpc-0123456789abcdef0"
    subnet_ids  = ["subnet-0aaa1111bbbb2222c", "subnet-0ddd3333eeee4444f"]

    allowed_security_group_ids = ["sg-0clientaaaa1111bb"]

    users = [
      {
        username       = "mq-admin"
        password       = "<YOUR_BROKER_PASSWORD>" # placeholder — inject from a secrets manager (PCI DSS Req 8)
        console_access = true
      },
    ]
  }
}

output "broker_arn" {
  value = module.mq.manifest.broker_arn
}

output "broker_endpoints" {
  value = module.mq.manifest.broker_endpoints
}

output "security_group_id" {
  value = module.mq.manifest.security_group_id
}
