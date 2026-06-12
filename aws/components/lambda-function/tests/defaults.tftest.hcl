# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. Under the mock, computed ARNs/IDs are unknown, so we
# assert on known/derived values (module instance counts, derived log group
# name, manifest nullness) and on plan success rather than on computed ARNs.

mock_provider "aws" {}

variables {
  base = {
    name     = "test-fn"
    runtime  = "python3.12"
    handler  = "index.handler"
    filename = "build/function.zip"
  }
}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = var.base
  }

  # No BYO key -> the component creates a CMK.
  assert {
    condition     = length(module.kms_key) == 1
    error_message = "A CMK must be created when no BYO key is supplied."
  }

  # No VPC by default -> no security group.
  assert {
    condition     = length(module.security_group) == 0
    error_message = "No security group must be created without a VPC attachment."
  }

  # Log group name derived from the function name.
  assert {
    condition     = module.log_group.manifest.name == "/aws/lambda/test-fn"
    error_message = "Log group name must be /aws/lambda/<name>."
  }

  # Function name echoed through.
  assert {
    condition     = module.lambda_function.manifest.function_name == "test-fn"
    error_message = "Function name must equal config.name."
  }

  # Effective KMS ARN flows to the manifest (the created CMK arn, unknown under
  # mock but present); inline policies wired without VPC perms.
  assert {
    condition     = !contains(keys(local.inline_policies), "vpc-access")
    error_message = "VPC ENI permissions must not be attached when no VPC is configured."
  }

  # No VPC -> security_group_id is null in the manifest.
  assert {
    condition     = output.manifest.security_group_id == null
    error_message = "security_group_id must be null when no VPC is attached."
  }
}

run "byo_key_skips_kms_atom" {
  command = plan

  variables {
    config = merge(var.base, {
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    })
  }

  assert {
    condition     = length(module.kms_key) == 0
    error_message = "No CMK must be created when a BYO key is supplied."
  }

  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "Manifest kms_key_arn must be the BYO key."
  }
}

run "vpc_config_creates_security_group" {
  command = plan

  variables {
    config = merge(var.base, {
      vpc_id         = "vpc-00000000000000000"
      vpc_subnet_ids = ["subnet-00000000000000001", "subnet-00000000000000002"]
    })
  }

  assert {
    condition     = length(module.security_group) == 1
    error_message = "A security group must be created when vpc_subnet_ids is set."
  }
}

# Negative case (validation): VPC subnets without a vpc_id is rejected.
run "vpc_subnets_without_vpc_id_is_rejected" {
  command = plan

  variables {
    config = merge(var.base, {
      vpc_subnet_ids = ["subnet-00000000000000001"]
      # vpc_id omitted
    })
  }

  expect_failures = [
    var.config,
  ]
}
