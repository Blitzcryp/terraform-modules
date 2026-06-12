# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      alarm_name          = "unauthorized-api-calls"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "UnauthorizedAPICalls"
      namespace           = "CISBenchmark"
      alarm_actions       = ["arn:aws:sns:eu-central-1:123456789012:security-alerts"]
    }
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.treat_missing_data == "notBreaching"
    error_message = "treat_missing_data must default to notBreaching."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.period == 300
    error_message = "period must default to 300 seconds."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.statistic == "Sum"
    error_message = "statistic must default to Sum."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.this.threshold == 1
    error_message = "threshold must default to 1."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.this.alarm_actions) == 1
    error_message = "alarm_actions must carry the supplied SNS topic ARN."
  }
}

run "invalid_comparison_operator_is_rejected" {
  command = plan

  variables {
    config = {
      alarm_name          = "bad-op"
      comparison_operator = "NotARealOperator"
      evaluation_periods  = 1
      metric_name         = "UnauthorizedAPICalls"
      namespace           = "CISBenchmark"
    }
  }

  expect_failures = [
    var.config,
  ]
}

run "invalid_treat_missing_data_is_rejected" {
  command = plan

  variables {
    config = {
      alarm_name          = "bad-tmd"
      comparison_operator = "GreaterThanOrEqualToThreshold"
      evaluation_periods  = 1
      metric_name         = "UnauthorizedAPICalls"
      namespace           = "CISBenchmark"
      treat_missing_data  = "explode"
    }
  }

  expect_failures = [
    var.config,
  ]
}
