# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the atom's secure-by-default behaviour.
# NOTE: under mock_provider, the detector id/arn/account_id are unknown, so we
# assert on known/derived values (counts, feature statuses, settings).

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {}
  }

  assert {
    condition     = aws_guardduty_detector.this.enable == true
    error_message = "GuardDuty must be enabled by default."
  }

  assert {
    condition     = aws_guardduty_detector.this.finding_publishing_frequency == "FIFTEEN_MINUTES"
    error_message = "Finding publishing frequency must default to FIFTEEN_MINUTES."
  }

  # Three protection features are managed; S3 and malware ENABLED, k8s DISABLED.
  assert {
    condition     = length(aws_guardduty_detector_feature.this) == 3
    error_message = "All three protection features must be managed."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["S3_DATA_EVENTS"].status == "ENABLED"
    error_message = "S3 protection must be enabled by default."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["EBS_MALWARE_PROTECTION"].status == "ENABLED"
    error_message = "Malware protection must be enabled by default."
  }

  assert {
    condition     = aws_guardduty_detector_feature.this["EKS_AUDIT_LOGS"].status == "DISABLED"
    error_message = "Kubernetes protection must default to DISABLED."
  }
}

# Negative case: an invalid finding_publishing_frequency is rejected.
run "invalid_frequency_is_rejected" {
  command = plan

  variables {
    config = {
      finding_publishing_frequency = "DAILY"
    }
  }

  expect_failures = [
    var.config,
  ]
}
