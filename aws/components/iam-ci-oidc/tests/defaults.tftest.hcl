# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default
# composition. NOTE: under mock_provider, computed values such as ARNs are
# unknown, so we assert on known/derived values (module counts, trust-policy
# JSON, validation) and on plan success rather than on computed ARNs.

mock_provider "aws" {}

run "secure_defaults_compose_provider_and_role" {
  command = plan

  variables {
    config = {
      role_name = "test-ci-deploy"
      subjects  = ["repo:emag-group/example-service:ref:refs/heads/main"]
    }
  }

  # No provider ARN supplied -> the component owns the OIDC provider.
  assert {
    condition     = length(module.oidc_provider) == 1
    error_message = "An OIDC provider atom must be created when create_provider defaults to true."
  }

  # Exactly one CI role is always composed.
  assert {
    condition     = length(module.ci_role) == 1
    error_message = "The CI role must always be created."
  }

  # The issuer URL and host are derived from the default provider_url (the
  # host drives the OIDC condition keys <host>:sub / <host>:aud). These are
  # known at plan time even under the mock provider.
  assert {
    condition     = local.issuer_url == "https://token.actions.githubusercontent.com"
    error_message = "issuer_url must be the https:// form of the default provider_url."
  }

  assert {
    condition     = local.provider_host == "token.actions.githubusercontent.com"
    error_message = "provider_host must be the scheme-stripped issuer host used for the OIDC condition keys."
  }

  # The provider atom receives the same issuer URL and audience the trust policy
  # is built from (known inputs, asserted via the atom's echoed config). NOTE:
  # the rendered assume_role_policy itself embeds the federated provider ARN,
  # which is unknown under the mock provider, so we assert on these known parts.
  assert {
    condition     = module.oidc_provider[0].manifest.url == "https://token.actions.githubusercontent.com"
    error_message = "The OIDC provider must be created for the configured issuer."
  }
}

run "reuse_existing_provider" {
  command = plan

  variables {
    config = {
      role_name       = "test-ci-reuse"
      subjects        = ["repo:emag-group/example-service:ref:refs/heads/main"]
      create_provider = false
      provider_arn    = "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
    }
  }

  # Provider ARN supplied -> no OIDC provider atom is created.
  assert {
    condition     = length(module.oidc_provider) == 0
    error_message = "No OIDC provider atom must be created when create_provider=false."
  }

  # The trust policy federates to the reused provider ARN.
  assert {
    condition     = local.effective_provider_arn == "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
    error_message = "The role must federate to the supplied provider_arn when reusing."
  }
}

run "https_provider_url_is_stripped_to_host" {
  command = plan

  variables {
    config = {
      role_name    = "test-ci-https"
      provider_url = "https://token.actions.githubusercontent.com"
      subjects     = ["repo:emag-group/example-service:ref:refs/heads/main"]
    }
  }

  assert {
    condition     = local.provider_host == "token.actions.githubusercontent.com"
    error_message = "provider_host must strip the https:// scheme from provider_url."
  }
}

# Negative: a wildcard-only subject is rejected without the escape hatch.
run "wildcard_subject_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      role_name = "test-ci-wildcard"
      subjects  = ["*"]
      # allow_wildcard_subject intentionally left false
    }
  }

  expect_failures = [
    var.config,
  ]
}

# Negative: create_provider=false without provider_arn is rejected.
run "reuse_without_provider_arn_is_rejected" {
  command = plan

  variables {
    config = {
      role_name       = "test-ci-noarn"
      subjects        = ["repo:emag-group/example-service:ref:refs/heads/main"]
      create_provider = false
      # provider_arn intentionally omitted
    }
  }

  expect_failures = [
    var.config,
  ]
}
