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

# Minimal usage: alert on >= 1 unauthorized API call in a 5-minute window and
# notify an SNS topic (PCI DSS Req 10.6). The metric is fed by a companion
# cloudwatch-log-metric-filter on the CloudTrail log group.
module "metric_alarm" {
  source = "../.."

  config = {
    alarm_name          = "example-unauthorized-api-calls"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 1
    metric_name         = "UnauthorizedAPICalls"
    namespace           = "CISBenchmark"
    period              = 300
    statistic           = "Sum"
    threshold           = 1
    alarm_description   = "CIS 3.1 / PCI Req 10.6: one or more unauthorized API calls detected."

    # In a real deployment this comes from the sns-topic atom's `arn` output.
    alarm_actions = ["arn:aws:sns:eu-central-1:123456789012:security-alerts"]

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "alarm_arn" {
  value = module.metric_alarm.manifest.arn
}
