# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# Under the mock, ARNs/IDs are unknown, so assertions target known/derived config
# values and module counts. nonsensitive() is used where the client_secret taints
# the manifest object.

mock_provider "aws" {}

run "secure_defaults_compose_pool_and_client" {
  command = plan

  variables {
    config = {
      name = "test-auth"
    }
  }

  # --- Pool is hardened ---
  assert {
    condition     = module.user_pool.manifest.name == "test-auth"
    error_message = "Pool name must be threaded from the component config."
  }

  # MFA enforcement is proven positively here (the secure default plans cleanly
  # with mfa_configuration=ON) and negatively in mfa_off_is_rejected below. The
  # pool atom's own tests assert the underlying aws_cognito_user_pool wiring
  # (TOTP, advanced security ENFORCED, password complexity).
  assert {
    condition     = var.config.mfa_configuration == "ON"
    error_message = "Component must enforce MFA ON (PCI DSS Req 8.4 / 8.5)."
  }

  assert {
    condition     = var.config.password_minimum_length == 14
    error_message = "Component must default to a 14-char minimum password length (PCI DSS Req 8.3.6)."
  }

  # --- Client is hardened (read via the client atom's manifest) ---
  assert {
    condition     = nonsensitive(module.user_pool_client.manifest.generate_secret) == true
    error_message = "Component must generate a confidential client secret by default."
  }

  assert {
    condition     = !contains(nonsensitive(module.user_pool_client.manifest.explicit_auth_flows), "ALLOW_USER_PASSWORD_AUTH")
    error_message = "Component client must exclude the password auth flow (PCI DSS Req 8)."
  }

  assert {
    condition     = !contains(nonsensitive(module.user_pool_client.manifest.allowed_oauth_flows), "implicit")
    error_message = "Component client must never allow the implicit OAuth flow."
  }

  assert {
    condition     = nonsensitive(module.user_pool_client.manifest.name) == "test-auth-client"
    error_message = "Client name must derive from the component name."
  }

  # --- No domain unless requested ---
  assert {
    condition     = length(module.user_pool_domain) == 0
    error_message = "Domain atom must not be created when config.domain is unset."
  }

  assert {
    condition     = nonsensitive(output.manifest.domain) == null
    error_message = "Manifest domain must be null when no domain is requested."
  }
}

run "domain_is_created_when_requested" {
  command = plan

  variables {
    config = {
      name   = "test-auth"
      domain = "test-auth-emag"
    }
  }

  assert {
    condition     = length(module.user_pool_domain) == 1
    error_message = "Domain atom must be created when config.domain is set."
  }

  assert {
    condition     = module.user_pool_domain[0].manifest.domain == "test-auth-emag"
    error_message = "Domain must be threaded from the component config."
  }

  assert {
    condition     = nonsensitive(output.manifest.domain) == "test-auth-emag"
    error_message = "Manifest domain must reflect the requested domain."
  }
}

run "short_password_is_rejected" {
  command = plan

  variables {
    config = {
      name                    = "test-auth"
      password_minimum_length = 8
    }
  }

  # No escape hatch at the component — rejected by config validation.
  expect_failures = [
    var.config,
  ]
}

run "mfa_off_is_rejected" {
  command = plan

  variables {
    config = {
      name              = "test-auth"
      mfa_configuration = "OFF"
    }
  }

  # The component enforces MFA ON with no escape hatch.
  expect_failures = [
    var.config,
  ]
}
