# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the atom's behaviour and validation.
# NOTE: under mock_provider the provider ARN is unknown, so we assert on known
# inputs (url, audience, empty thumbprints) and on plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      url            = "https://token.actions.githubusercontent.com"
      client_id_list = ["sts.amazonaws.com"]
    }
  }

  assert {
    condition     = aws_iam_openid_connect_provider.this.url == "https://token.actions.githubusercontent.com"
    error_message = "url must echo the configured issuer."
  }

  assert {
    condition     = length(aws_iam_openid_connect_provider.this.thumbprint_list) == 0
    error_message = "thumbprint_list must default to empty (AWS manages thumbprints for known IdPs)."
  }

  assert {
    condition     = contains(aws_iam_openid_connect_provider.this.client_id_list, "sts.amazonaws.com")
    error_message = "client_id_list must contain the configured audience."
  }
}

run "non_https_url_is_rejected" {
  command = plan

  variables {
    config = {
      url            = "token.actions.githubusercontent.com"
      client_id_list = ["sts.amazonaws.com"]
    }
  }

  expect_failures = [
    var.config,
  ]
}

run "empty_client_id_list_is_rejected" {
  command = plan

  variables {
    config = {
      url            = "https://token.actions.githubusercontent.com"
      client_id_list = []
    }
  }

  expect_failures = [
    var.config,
  ]
}
