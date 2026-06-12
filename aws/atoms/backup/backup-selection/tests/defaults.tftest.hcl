# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. Under mock_provider, computed values such as id are
# unknown, so we assert on known/derived values and on plan success.

mock_provider "aws" {}

run "tag_based_selection_defaults" {
  command = plan

  variables {
    config = {
      name         = "test-selection"
      plan_id      = "00000000-0000-0000-0000-000000000000"
      iam_role_arn = "arn:aws:iam::111122223333:role/test-backup-role"
      selection_tags = [
        {
          key   = "Backup"
          value = "true"
        }
      ]
    }
  }

  assert {
    condition     = aws_backup_selection.this.name == "test-selection"
    error_message = "Selection name must be derived from config.name."
  }

  # selection_tag type defaults to STRINGEQUALS.
  assert {
    condition     = one(aws_backup_selection.this.selection_tag).type == "STRINGEQUALS"
    error_message = "selection_tag.type must default to STRINGEQUALS."
  }

  assert {
    condition     = aws_backup_selection.this.iam_role_arn == "arn:aws:iam::111122223333:role/test-backup-role"
    error_message = "Selection must assume the supplied IAM role."
  }
}

run "resource_arn_selection" {
  command = plan

  variables {
    config = {
      name         = "test-selection-arns"
      plan_id      = "00000000-0000-0000-0000-000000000000"
      iam_role_arn = "arn:aws:iam::111122223333:role/test-backup-role"
      resources    = ["arn:aws:dynamodb:eu-central-1:111122223333:table/orders"]
    }
  }

  assert {
    condition     = length(aws_backup_selection.this.resources) == 1
    error_message = "Selection must include the supplied resource ARNs."
  }
}

run "rejects_empty_target" {
  command = plan

  variables {
    config = {
      name         = "test-selection-empty"
      plan_id      = "00000000-0000-0000-0000-000000000000"
      iam_role_arn = "arn:aws:iam::111122223333:role/test-backup-role"
      # neither resources nor selection_tags set
    }
  }

  expect_failures = [
    var.config,
  ]
}

run "rejects_invalid_iam_role_arn" {
  command = plan

  variables {
    config = {
      name         = "test-selection-badrole"
      plan_id      = "00000000-0000-0000-0000-000000000000"
      iam_role_arn = "not-an-arn"
      resources    = ["arn:aws:dynamodb:eu-central-1:111122223333:table/orders"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
