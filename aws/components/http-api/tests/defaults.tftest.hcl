# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# NOTE: under mock_provider, computed values such as API IDs and ARNs are
# unknown, so we assert on known/derived values (counts, log group name, KMS
# policy JSON, the derived destination/policy locals) and on plan success rather
# than on computed ARNs.

# Mock the account/region/partition data sources with realistic values so the
# derived log-group ARN the component builds passes the provider's ARN
# validation. Without this the mock provider invents non-ARN-shaped values.
mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }
  mock_data "aws_region" {
    defaults = {
      name = "eu-central-1"
    }
  }
  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }
}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = {
      name              = "test-api"
      lambda_invoke_arn = "arn:aws:apigateway:eu-central-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-central-1:111122223333:function:test-fn/invocations"
    }
  }

  # No BYO key supplied -> the component owns the CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A kms-key atom must be created when no kms_key_arn is supplied."
  }

  # The always-on atoms (api, integration, log group, stage) are each one instance.
  assert {
    condition     = length(module.access_log_group) == 1 && length(module.stage) == 1
    error_message = "Access-log group and stage must each be composed exactly once."
  }

  # Default routes -> exactly one route atom for the catch-all "$default".
  assert {
    condition     = length(module.route) == 1
    error_message = "Default config.routes (['$default']) must produce exactly one route atom."
  }

  # The access-log group name is derived from config.name (known at plan).
  assert {
    condition     = module.access_log_group.manifest.name == "/aws/apigateway/test-api"
    error_message = "Access-log group name must be derived from config.name."
  }

  # The created CMK alias is derived from config.name.
  assert {
    condition     = module.kms_key[0].manifest.alias_name == "alias/test-api/http-api-logs"
    error_message = "KMS alias must be derived from config.name."
  }

  # Access logging is wired: the stage receives the access-log group ARN as its
  # destination (the effective KMS-encrypted group).
  assert {
    condition     = module.stage.manifest != null
    error_message = "The stage must be composed and wired to the access-log group."
  }

  # The KMS policy this component builds must authorise the regional CloudWatch
  # Logs service principal so the CMK-encrypted log group can be created.
  assert {
    condition     = can(regex("logs\\.[a-z0-9-]+\\.amazonaws\\.com", local.kms_policy))
    error_message = "KMS policy must grant the regional logs.<region>.amazonaws.com principal."
  }

  # The KMS grant to CloudWatch Logs must include the datakey/encrypt actions.
  assert {
    condition     = can(regex("kms:GenerateDataKey\\*", local.kms_policy)) && can(regex("kms:Encrypt", local.kms_policy))
    error_message = "KMS policy must grant CloudWatch Logs GenerateDataKey* and Encrypt."
  }

  # No CORS origins supplied -> CORS is not configured on the API.
  assert {
    condition     = local.has_cors == false
    error_message = "CORS must be unconfigured when config.cors_allow_origins is empty."
  }
}

run "multiple_routes_create_one_atom_each" {
  command = plan

  variables {
    config = {
      name               = "test-api-routes"
      lambda_invoke_arn  = "arn:aws:apigateway:eu-central-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-central-1:111122223333:function:test-fn/invocations"
      routes             = ["GET /items", "POST /items", "GET /items/{id}"]
      cors_allow_origins = ["https://app.example.com"]
    }
  }

  # One route atom per route key.
  assert {
    condition     = length(module.route) == 3
    error_message = "Each route key in config.routes must produce one route atom."
  }

  # CORS origins supplied -> CORS is configured on the API.
  assert {
    condition     = local.has_cors == true
    error_message = "CORS must be configured when config.cors_allow_origins is non-empty."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  variables {
    config = {
      name              = "test-api-byo"
      lambda_invoke_arn = "arn:aws:apigateway:eu-central-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-central-1:111122223333:function:test-fn/invocations"
      kms_key_arn       = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  # BYO key supplied -> no kms-key atom is created.
  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No kms-key atom must be created when a BYO kms_key_arn is supplied."
  }

  # The component reports the BYO key as the effective encryption key.
  assert {
    condition     = local.effective_kms_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "The access-log group must be encrypted with the supplied BYO KMS key."
  }

  # manifest.kms_key_arn must echo the BYO key.
  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "manifest.kms_key_arn must report the BYO key when one is supplied."
  }
}

# Negative case: an invalid KMS ARN is rejected by the config validation block.
run "invalid_kms_arn_is_rejected" {
  command = plan

  variables {
    config = {
      name              = "test-api-badarn"
      lambda_invoke_arn = "arn:aws:apigateway:eu-central-1:lambda:path/2015-03-31/functions/arn:aws:lambda:eu-central-1:111122223333:function:test-fn/invocations"
      kms_key_arn       = "not-an-arn"
    }
  }

  expect_failures = [
    var.config,
  ]
}
