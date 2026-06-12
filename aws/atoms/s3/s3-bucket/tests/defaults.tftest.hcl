# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      bucket = "emag-test-pci-bucket"
    }
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.this[0].rule).apply_server_side_encryption_by_default).sse_algorithm == "aws:kms"
    error_message = "Server-side encryption must default to aws:kms (PCI DSS Req 3)."
  }

  assert {
    condition     = one(aws_s3_bucket_server_side_encryption_configuration.this[0].rule).bucket_key_enabled == true
    error_message = "Bucket key must be enabled by default."
  }

  assert {
    condition     = aws_s3_bucket_versioning.this.versioning_configuration[0].status == "Enabled"
    error_message = "Versioning must default to Enabled."
  }

  assert {
    condition = (
      aws_s3_bucket_public_access_block.this.block_public_acls &&
      aws_s3_bucket_public_access_block.this.block_public_policy &&
      aws_s3_bucket_public_access_block.this.ignore_public_acls &&
      aws_s3_bucket_public_access_block.this.restrict_public_buckets
    )
    error_message = "All four public access block flags must default to true."
  }

  assert {
    condition     = aws_s3_bucket_ownership_controls.this.rule[0].object_ownership == "BucketOwnerEnforced"
    error_message = "Object ownership must default to BucketOwnerEnforced (ACLs disabled)."
  }
}

run "unencrypted_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      bucket            = "emag-test-pci-bucket"
      enable_encryption = false
      # allow_unencrypted intentionally left false
    }
  }

  expect_failures = [
    aws_s3_bucket.this,
  ]
}

run "unversioned_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      bucket            = "emag-test-pci-bucket"
      enable_versioning = false
      # allow_unversioned intentionally left false
    }
  }

  expect_failures = [
    aws_s3_bucket.this,
  ]
}

run "public_access_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      bucket              = "emag-test-pci-bucket"
      block_public_access = false
      # allow_public_access intentionally left false
    }
  }

  expect_failures = [
    aws_s3_bucket.this,
  ]
}

run "bucket_name_validation_rejects_invalid" {
  command = plan

  variables {
    config = {
      bucket = "Invalid_Bucket_NAME"
    }
  }

  expect_failures = [
    var.config,
  ]
}
