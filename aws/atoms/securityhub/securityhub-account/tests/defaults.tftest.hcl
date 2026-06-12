# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour.
# NOTE: under mock_provider, the account ARN/id is unknown, so we assert on
# known/derived values (counts, control settings, derived standard ARNs).

mock_provider "aws" {}

# Pin region/partition so the derived standard ARNs are valid (the mock provider
# would otherwise generate random strings that fail the resource's ARN check).
override_data {
  target = data.aws_region.current
  values = {
    name = "eu-central-1"
  }
}

override_data {
  target = data.aws_partition.current
  values = {
    partition = "aws"
  }
}

run "secure_defaults" {
  command = plan

  variables {
    config = {}
  }

  assert {
    condition     = aws_securityhub_account.this.enable_default_standards == true
    error_message = "Default standards must be enabled by default."
  }

  assert {
    condition     = aws_securityhub_account.this.control_finding_generator == "SECURITY_CONTROL"
    error_message = "Control findings must be consolidated (SECURITY_CONTROL) by default."
  }

  assert {
    condition     = aws_securityhub_account.this.auto_enable_controls == true
    error_message = "New controls must be auto-enabled by default."
  }

  # Two curated default standards are subscribed (CIS + FSBP).
  assert {
    condition     = length(aws_securityhub_standards_subscription.this) == 2
    error_message = "Both the CIS and FSBP default standards must be subscribed by default."
  }

  # The FSBP standard ARN is region/partition-aware (derived, known at plan time).
  assert {
    condition     = contains([for s in aws_securityhub_standards_subscription.this : s.standards_arn], "arn:aws:securityhub:eu-central-1::standards/aws-foundational-security-best-practices/v/1.0.0")
    error_message = "FSBP standard ARN must be built region/partition-aware."
  }
}

run "explicit_standards_override" {
  command = plan

  variables {
    config = {
      standards_arns = ["arn:aws:securityhub:::ruleset/cis-aws-foundations-benchmark/v/1.2.0"]
    }
  }

  assert {
    condition     = length(aws_securityhub_standards_subscription.this) == 1
    error_message = "Explicit standards_arns must override the curated default list."
  }
}

# Negative case: an invalid control_finding_generator is rejected by validation.
run "invalid_finding_generator_is_rejected" {
  command = plan

  variables {
    config = {
      control_finding_generator = "NOPE"
    }
  }

  expect_failures = [
    var.config,
  ]
}
