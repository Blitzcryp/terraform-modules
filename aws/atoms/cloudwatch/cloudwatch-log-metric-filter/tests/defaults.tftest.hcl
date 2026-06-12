# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name           = "unauthorized-api-calls"
      log_group_name = "/aws/cloudtrail/test"
      pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"
      metric_name    = "UnauthorizedAPICalls"
    }
  }

  assert {
    condition     = one(aws_cloudwatch_log_metric_filter.this.metric_transformation).namespace == "CISBenchmark"
    error_message = "metric namespace must default to CISBenchmark (CIS AWS Foundations recipe)."
  }

  assert {
    condition     = one(aws_cloudwatch_log_metric_filter.this.metric_transformation).value == "1"
    error_message = "metric value must default to \"1\" (count of matching events)."
  }

  assert {
    condition     = one(aws_cloudwatch_log_metric_filter.this.metric_transformation).name == "UnauthorizedAPICalls"
    error_message = "metric_transformation.name must be the supplied metric_name."
  }
}

run "empty_name_is_rejected" {
  command = plan

  variables {
    config = {
      name           = ""
      log_group_name = "/aws/cloudtrail/test"
      pattern        = "{ ($.errorCode = \"AccessDenied*\") }"
      metric_name    = "UnauthorizedAPICalls"
    }
  }

  expect_failures = [
    var.config,
  ]
}
