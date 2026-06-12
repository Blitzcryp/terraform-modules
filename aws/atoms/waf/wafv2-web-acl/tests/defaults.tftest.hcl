# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name                = "test-web-acl"
      log_destination_arn = "arn:aws:logs:eu-central-1:123456789012:log-group:aws-waf-logs-test:*"
    }
  }

  assert {
    condition     = one(aws_wafv2_web_acl.this.default_action[0].allow) != null
    error_message = "default_action must default to allow."
  }

  assert {
    condition     = length(aws_wafv2_web_acl.this.rule) == 3
    error_message = "The three AWS managed rule groups must be present by default."
  }

  assert {
    condition     = length([for r in aws_wafv2_web_acl.this.rule : r.name if contains(["AWSManagedRulesCommonRuleSet", "AWSManagedRulesKnownBadInputsRuleSet", "AWSManagedRulesSQLiRuleSet"], r.name)]) == 3
    error_message = "Common, KnownBadInputs and SQLi managed rule groups must all be enabled."
  }

  assert {
    condition     = aws_wafv2_web_acl.this.visibility_config[0].cloudwatch_metrics_enabled == true && aws_wafv2_web_acl.this.visibility_config[0].sampled_requests_enabled == true
    error_message = "Web ACL visibility metrics and request sampling must be enabled."
  }

  assert {
    condition     = alltrue([for r in aws_wafv2_web_acl.this.rule : r.visibility_config[0].cloudwatch_metrics_enabled && r.visibility_config[0].sampled_requests_enabled])
    error_message = "Every rule must have visibility metrics and request sampling enabled."
  }

  assert {
    condition     = length(aws_wafv2_web_acl_logging_configuration.this) == 1
    error_message = "Logging configuration must be created when a destination ARN is set."
  }
}

run "rate_limit_adds_rule" {
  command = plan

  variables {
    config = {
      name                = "test-web-acl"
      log_destination_arn = "arn:aws:logs:eu-central-1:123456789012:log-group:aws-waf-logs-test:*"
      rate_limit          = 2000
    }
  }

  assert {
    condition     = length(aws_wafv2_web_acl.this.rule) == 4
    error_message = "Setting rate_limit must add a fourth (rate-based) rule."
  }
}

run "logging_disabled_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name = "test-web-acl"
      # log_destination_arn omitted, allow_logging_disabled left at false default
    }
  }

  expect_failures = [
    aws_wafv2_web_acl.this,
  ]
}

run "logging_disabled_allowed_with_escape_hatch" {
  command = plan

  variables {
    config = {
      name                   = "test-web-acl"
      allow_logging_disabled = true
    }
  }

  assert {
    condition     = length(aws_wafv2_web_acl_logging_configuration.this) == 0
    error_message = "No logging configuration should be created when logging is intentionally disabled."
  }
}

run "scope_validation_rejects_bad_value" {
  command = plan

  variables {
    config = {
      name                = "test-web-acl"
      log_destination_arn = "arn:aws:logs:eu-central-1:123456789012:log-group:aws-waf-logs-test:*"
      scope               = "GLOBAL"
    }
  }

  expect_failures = [
    var.config,
  ]
}
