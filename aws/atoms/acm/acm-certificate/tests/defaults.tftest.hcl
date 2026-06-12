# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. The ARN, status and domain_validation_options are unknown
# under the mock provider, so assertions target the known/derived input values
# (domain_name, SANs, validation_method, key_algorithm).

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      domain_name = "app.example.com"
    }
  }

  assert {
    condition     = aws_acm_certificate.this.validation_method == "DNS"
    error_message = "validation_method must default to DNS (fully automatable)."
  }

  assert {
    condition     = aws_acm_certificate.this.key_algorithm == "RSA_2048"
    error_message = "key_algorithm must default to RSA_2048."
  }

  assert {
    condition     = aws_acm_certificate.this.domain_name == "app.example.com"
    error_message = "domain_name must be planned with the requested value."
  }
}

run "subject_alternative_names_flow_through" {
  command = plan

  variables {
    config = {
      domain_name               = "app.example.com"
      subject_alternative_names = ["www.app.example.com", "api.example.com"]
    }
  }

  assert {
    condition     = length(aws_acm_certificate.this.subject_alternative_names) == 2
    error_message = "subject_alternative_names must flow through to the certificate."
  }
}

# --- Negative case: an unsupported validation method is rejected by config validation. ---
run "invalid_validation_method_is_rejected" {
  command = plan

  variables {
    config = {
      domain_name       = "app.example.com"
      validation_method = "PHONE"
    }
  }

  expect_failures = [
    var.config,
  ]
}
