# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed.
#
# IMPORTANT: under mock_provider the certificate's domain_validation_options are
# UNKNOWN at plan time, so the for_each over validation records cannot be
# enumerated and concrete record contents/fqdns are not assertable. These tests
# therefore assert plan success and the presence/derived inputs of the composed
# atoms (the certificate and the validation modules) plus config validation.
# Concrete validation-record behaviour must be verified against a real
# `terraform apply` (see apply-time notes in the README).

mock_provider "aws" {}

run "secure_defaults_compose_dns_validated_cert" {
  command = plan

  variables {
    config = {
      domain_name    = "app.example.com"
      hosted_zone_id = "Z01234567ABCDEFGHIJK"
    }
  }

  # The certificate atom is requested with DNS validation and the configured domain.
  assert {
    condition     = module.certificate.manifest.domain_name == "app.example.com"
    error_message = "The certificate atom must be requested for the configured domain_name."
  }

  # One validation record per distinct domain (single domain, no SANs => 1).
  assert {
    condition     = length(module.validation_record) == 1
    error_message = "Exactly one validation record must be created for a single-domain certificate."
  }
}

run "with_subject_alternative_names" {
  command = plan

  variables {
    config = {
      domain_name               = "app.example.com"
      subject_alternative_names = ["www.app.example.com", "api.example.com"]
      hosted_zone_id            = "Z01234567ABCDEFGHIJK"
    }
  }

  assert {
    condition     = module.certificate.manifest.domain_name == "app.example.com"
    error_message = "The certificate atom must be requested for the configured domain_name even with SANs."
  }

  # One validation record per distinct domain: primary + 2 SANs => 3.
  assert {
    condition     = length(module.validation_record) == 3
    error_message = "One validation record must be created per distinct domain (primary + SANs)."
  }
}

# --- Negative case: empty hosted_zone_id is rejected by config validation. ---
run "empty_hosted_zone_id_is_rejected" {
  command = plan

  variables {
    config = {
      domain_name    = "app.example.com"
      hosted_zone_id = ""
    }
  }

  expect_failures = [
    var.config,
  ]
}
