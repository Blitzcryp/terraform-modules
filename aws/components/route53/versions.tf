terraform {
  required_version = ">= 1.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.60"
      # Public-zone query logs must be delivered to a us-east-1 CloudWatch Logs
      # group. The caller passes a us-east-1-aliased provider as `aws.use1`.
      configuration_aliases = [aws, aws.use1]
    }
  }
}
