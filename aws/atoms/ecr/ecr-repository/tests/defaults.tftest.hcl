# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name = "platform/example-service"
    }
  }

  assert {
    condition     = aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push == true
    error_message = "scan_on_push must default to true (PCI DSS Req 6)."
  }

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "IMMUTABLE"
    error_message = "image_tag_mutability must default to IMMUTABLE (image integrity)."
  }

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].encryption_type == "AES256"
    error_message = "Encryption must default to AES256 when no KMS key is supplied (PCI DSS Req 3)."
  }

  assert {
    condition     = aws_ecr_repository.this.force_delete == false
    error_message = "force_delete must default to false."
  }

  # Lifecycle policy is a tightly-coupled sub-resource and always present.
  assert {
    condition     = aws_ecr_lifecycle_policy.this.repository != null
    error_message = "A lifecycle policy must always be attached."
  }

  # No repository policy unless explicitly provided.
  assert {
    condition     = length(aws_ecr_repository_policy.this) == 0
    error_message = "Repository policy must not be created unless additional_repository_policy is set."
  }
}

run "kms_encryption_when_key_supplied" {
  command = plan

  variables {
    config = {
      name        = "platform/example-service"
      kms_key_arn = "arn:aws:kms:eu-central-1:123456789012:key/abcd1234-5678-90ab-cdef-1234567890ab"
    }
  }

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].encryption_type == "KMS"
    error_message = "Supplying kms_key_arn must select KMS encryption."
  }
}

run "scan_on_push_disabled_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name         = "platform/example-service"
      scan_on_push = false
      # allow_scan_on_push_disabled left at its false default
    }
  }

  expect_failures = [
    aws_ecr_repository.this,
  ]
}

run "tag_mutability_validation_rejects_bad_value" {
  command = plan

  variables {
    config = {
      name                 = "platform/example-service"
      image_tag_mutability = "SOMETIMES"
    }
  }

  expect_failures = [
    var.config,
  ]
}
