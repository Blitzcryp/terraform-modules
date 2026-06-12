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

# Minimal, PCI-compliant usage: creates a private broker security group (Kafka
# TLS ports only, ingress from the supplied client SG), a CloudWatch-Logs- and
# MSK-authorised CMK, a CMK-encrypted broker log group with 365-day retention,
# and an MSK cluster with TLS in transit, CMK at rest, SASL/IAM auth and broker
# logging. Subnet/SG IDs below are placeholders.
module "kafka" {
  source = "../.."

  config = {
    name           = "example-kafka"
    vpc_id         = "vpc-0123456789abcdef0"
    client_subnets = ["subnet-0aaa1111bbbb2222c", "subnet-0ddd3333eeee4444f", "subnet-0fff5555aaaa6666b"]

    # Admit only this client security group on the Kafka TLS ports.
    allowed_security_group_ids = ["sg-0clientaaaa1111bb"]
  }
}

output "cluster_arn" {
  value = module.kafka.manifest.cluster_arn
}

output "bootstrap_brokers_tls" {
  value = module.kafka.manifest.bootstrap_brokers_tls
}

output "security_group_id" {
  value = module.kafka.manifest.security_group_id
}
