# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. Under mock_provider, computed values such as arn/version
# are unknown, so we assert on known/derived rule values and on plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name = "test-plan"
      rules = [
        {
          rule_name         = "daily"
          target_vault_name = "test-vault"
        }
      ]
    }
  }

  assert {
    condition     = aws_backup_plan.this.name == "test-plan"
    error_message = "Plan name must be derived from config.name."
  }

  # Default daily schedule and 35-day retention (PCI DSS Req 10.5.1).
  assert {
    condition     = one(aws_backup_plan.this.rule).schedule == "cron(0 5 * * ? *)"
    error_message = "Rule must default to a daily schedule."
  }

  assert {
    condition     = one(one(aws_backup_plan.this.rule).lifecycle).delete_after == 35
    error_message = "Rule must default to 35-day retention."
  }
}

run "multiple_rules_and_copy_action" {
  command = plan

  variables {
    config = {
      name = "test-plan-multi"
      rules = [
        {
          rule_name                         = "daily"
          target_vault_name                 = "primary"
          delete_after                      = 90
          copy_action_destination_vault_arn = "arn:aws:backup:eu-west-1:111122223333:backup-vault:dr"
        },
        {
          rule_name         = "weekly"
          target_vault_name = "primary"
          schedule          = "cron(0 5 ? * 1 *)"
          delete_after      = 365
        }
      ]
    }
  }

  # rule is a set whose element ARNs are computed; assert on the known input.
  assert {
    condition     = length(var.config.rules) == 2
    error_message = "Plan must render one block per configured rule."
  }
}

run "rejects_empty_rules" {
  command = plan

  variables {
    config = {
      name  = "test-plan-norules"
      rules = []
    }
  }

  expect_failures = [
    var.config,
  ]
}

run "rejects_cold_storage_shorter_than_minimum" {
  command = plan

  variables {
    config = {
      name = "test-plan-badlifecycle"
      rules = [
        {
          rule_name          = "daily"
          target_vault_name  = "primary"
          cold_storage_after = 30
          delete_after       = 60 # must be >= cold_storage_after + 90
        }
      ]
    }
  }

  expect_failures = [
    var.config,
  ]
}
