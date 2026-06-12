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

# A connection-pooling proxy in front of a PostgreSQL DB instance. TLS is
# required, authentication is delegated to Secrets Manager + IAM, and the proxy
# reads DB credentials from the referenced secret. Subnet/SG/secret/role
# identifiers are fake placeholders for the example only.
module "rds_proxy" {
  source = "../.."

  config = {
    name          = "example-pg-proxy"
    engine_family = "POSTGRESQL"
    secret_arns = [
      "arn:aws:secretsmanager:eu-central-1:111122223333:secret:example-db-creds-AbCdEf",
    ]
    role_arn       = "arn:aws:iam::111122223333:role/example-rds-proxy"
    vpc_subnet_ids = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
    vpc_security_group_ids = [
      "sg-0123456789abcdef0",
    ]

    target_db_instance_identifier = "example-postgres"

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "proxy_endpoint" {
  value = module.rds_proxy.manifest.endpoint
}
