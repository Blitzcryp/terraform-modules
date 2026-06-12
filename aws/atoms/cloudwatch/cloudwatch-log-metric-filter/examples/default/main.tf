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

# Minimal usage: emit a CISBenchmark metric for every unauthorized API call seen
# in the CloudTrail->CloudWatch Logs group (CIS 3.1 / PCI Req 10.6). Pair with a
# cloudwatch-metric-alarm to alert when the count breaches the threshold.
module "log_metric_filter" {
  source = "../.."

  config = {
    name           = "example-unauthorized-api-calls"
    log_group_name = "/aws/cloudtrail/example"
    pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
    metric_name    = "UnauthorizedAPICalls"

    # Secure defaults inherited: namespace=CISBenchmark, value="1".

    tags = {
      Environment = "example"
      Owner       = "platform"
    }
  }
}

output "filter_id" {
  value = module.log_metric_filter.manifest.id
}
