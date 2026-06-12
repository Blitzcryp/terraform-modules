# Native `terraform test`. Uses a mocked AWS provider (default + us-east-1 alias)
# so no real credentials or resources are needed — validates the component's
# secure-by-default composition. Under mock_provider, computed values such as
# ARNs are unknown, so we assert on known/derived values (counts, names,
# policy JSON, validation) and manifest nullness rather than computed ARNs.

# A 12-digit account id so derived ARNs (query-log destination) pass the AWS
# provider's ARN validation under the mock.
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }
}
mock_provider "aws" {
  alias = "use1"
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }
}

run "public_zone_composes_all_atoms" {
  command = plan

  providers = {
    aws      = aws
    aws.use1 = aws.use1
  }

  variables {
    config = {
      name = "example.com"
    }
  }

  # No BYO key -> the component owns the CMK (one kms-key atom, in us-east-1).
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created for a public zone when no kms_key_arn is supplied."
  }

  # Public zone -> a query-log group atom is created.
  assert {
    condition     = length(module.query_log_group) == 1
    error_message = "A query-log group must be created for a public zone."
  }

  # The CMK policy must authorise the us-east-1 CloudWatch Logs service principal
  # (apply-time correctness for the CMK-encrypted us-east-1 log group).
  assert {
    condition     = can(regex("logs\\.us-east-1\\.amazonaws\\.com", local.kms_policy))
    error_message = "KMS policy must grant the us-east-1 CloudWatch Logs service principal use of the key."
  }

  # Log group name and zone name are known at plan time (atoms echo inputs).
  assert {
    condition     = module.query_log_group[0].manifest.name == "/aws/route53/example.com"
    error_message = "Query-log group name must be derived from the zone name."
  }

  assert {
    condition     = module.zone.manifest.name == "example.com"
    error_message = "Zone name must be passed through to the route53-zone atom."
  }
}

run "private_zone_skips_query_logging" {
  command = plan

  providers = {
    aws      = aws
    aws.use1 = aws.use1
  }

  variables {
    config = {
      name         = "internal.example"
      private_zone = true
      vpc_ids      = ["vpc-0123456789abcdef0"]
    }
  }

  # Private zones cannot query-log -> no CMK, no log group.
  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No CMK must be created for a private zone (query logging unsupported)."
  }

  assert {
    condition     = length(module.query_log_group) == 0
    error_message = "No query-log group must be created for a private zone."
  }

  # Manifest reports null query_log_group_name for private zones.
  assert {
    condition     = output.manifest.query_log_group_name == null
    error_message = "query_log_group_name must be null for a private zone."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  providers = {
    aws      = aws
    aws.use1 = aws.use1
  }

  variables {
    config = {
      name        = "byo.example.com"
      kms_key_arn = "arn:aws:kms:us-east-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when a BYO kms_key_arn is supplied."
  }

  assert {
    condition     = local.effective_kms_arn == "arn:aws:kms:us-east-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "The query-log group must be encrypted with the supplied BYO key."
  }
}

# Negative case: a private zone with no VPC ids is rejected by config validation.
run "private_zone_without_vpc_is_rejected" {
  command = plan

  providers = {
    aws      = aws
    aws.use1 = aws.use1
  }

  variables {
    config = {
      name         = "internal.example"
      private_zone = true
      vpc_ids      = []
    }
  }

  expect_failures = [
    var.config,
  ]
}
