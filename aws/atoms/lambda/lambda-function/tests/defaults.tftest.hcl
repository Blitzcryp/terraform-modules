# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. Under the mock, computed ARNs/IDs are unknown, so we
# assert on known/derived values (echoed names, default args, dynamic-block
# presence) and on plan success rather than on computed ARNs.

mock_provider "aws" {}

variables {
  base = {
    function_name = "test-fn"
    role          = "arn:aws:iam::111122223333:role/test-fn-exec"
    runtime       = "python3.12"
    handler       = "index.handler"
    filename      = "build/function.zip"
    kms_key_arn   = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
  }
}

run "secure_defaults" {
  command = plan

  variables {
    config = var.base
  }

  # X-Ray active tracing on by default (PCI DSS Req 10).
  assert {
    condition     = aws_lambda_function.this.tracing_config[0].mode == "Active"
    error_message = "X-Ray tracing must default to Active mode."
  }

  # arm64 by default.
  assert {
    condition     = aws_lambda_function.this.architectures[0] == "arm64"
    error_message = "architectures must default to arm64."
  }

  # Secure sizing defaults.
  assert {
    condition     = aws_lambda_function.this.memory_size == 128 && aws_lambda_function.this.timeout == 3
    error_message = "memory_size/timeout must default to 128/3."
  }

  # CMK threaded to the function for env-var encryption at rest.
  assert {
    condition     = aws_lambda_function.this.kms_key_arn == var.base.kms_key_arn
    error_message = "kms_key_arn must be passed to the function."
  }

  # No VPC config when no subnets supplied.
  assert {
    condition     = length(aws_lambda_function.this.vpc_config) == 0
    error_message = "No vpc_config block when vpc_subnet_ids is empty."
  }
}

run "env_vars_without_cmk_is_blocked" {
  command = plan

  variables {
    config = {
      function_name         = "test-fn"
      role                  = "arn:aws:iam::111122223333:role/test-fn-exec"
      runtime               = "python3.12"
      handler               = "index.handler"
      filename              = "build/function.zip"
      environment_variables = { LOG_LEVEL = "INFO" }
      # kms_key_arn omitted and allow_unencrypted_env left at its false default
    }
  }

  expect_failures = [
    aws_lambda_function.this,
  ]
}

run "zip_without_code_source_is_rejected" {
  command = plan

  variables {
    config = {
      function_name = "test-fn"
      role          = "arn:aws:iam::111122223333:role/test-fn-exec"
      runtime       = "python3.12"
      handler       = "index.handler"
      # no filename / s3 source
    }
  }

  expect_failures = [
    var.config,
  ]
}

run "image_package_type" {
  command = plan

  variables {
    config = {
      function_name = "test-fn"
      role          = "arn:aws:iam::111122223333:role/test-fn-exec"
      package_type  = "Image"
      image_uri     = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/test-fn:latest"
    }
  }

  assert {
    condition     = aws_lambda_function.this.package_type == "Image"
    error_message = "package_type must be Image when configured."
  }
}

run "vpc_attachment" {
  command = plan

  variables {
    config = merge(var.base, {
      vpc_subnet_ids         = ["subnet-00000000000000001"]
      vpc_security_group_ids = ["sg-00000000000000001"]
    })
  }

  assert {
    condition     = length(aws_lambda_function.this.vpc_config) == 1
    error_message = "vpc_config block must be present when vpc_subnet_ids is set."
  }
}
