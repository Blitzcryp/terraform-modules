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

# Minimal, PCI-compliant usage: the FULL CIS / PCI Req 10 monitoring baseline.
# Reads the CloudTrail->CloudWatch Logs group, creates an encrypted SNS topic
# (with a dedicated CMK) and wires one filter+alarm per security event to it.
module "cloudwatch_alarms" {
  source = "../.."

  config = {
    name_prefix = "emag-prod"

    # In a real deployment this is the cloudtrail component's
    # manifest.log_group_name output.
    cloudtrail_log_group_name = "/aws/cloudtrail/emag-prod"

    # sns_topic_arn / kms_key_arn omitted => an encrypted topic + CMK are created.
    # enabled_alarms omitted => the full baseline alarm set is provisioned.

    tags = {
      Environment = "production"
      Owner       = "security"
    }
  }
}

output "sns_topic_arn" {
  value = module.cloudwatch_alarms.manifest.sns_topic_arn
}

output "alarm_arns" {
  value = module.cloudwatch_alarms.manifest.alarm_arns
}
