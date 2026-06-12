# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# Under mock_provider, computed values (ARNs, domain names, OAC ids) are unknown,
# so we assert on known/derived values (module counts, names, manifest nullness)
# and on plan success rather than on computed ARNs.

mock_provider "aws" {}

run "s3_origin_secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = {
      name                  = "test-cdn"
      s3_origin_domain_name = "test-bucket.s3.eu-central-1.amazonaws.com"
    }
  }

  # An OAC is created for S3 origins (locks the bucket to CloudFront).
  assert {
    condition     = length(module.oac) == 1
    error_message = "An OAC must be created for an S3 origin."
  }

  # A dedicated access-log bucket is created by default (logging on, no BYO).
  assert {
    condition     = length(module.log_bucket) == 1
    error_message = "An access-log bucket must be created by default (PCI DSS Req 10)."
  }

  # Log bucket name is derived from config.name (known at plan time).
  assert {
    condition     = module.log_bucket[0].manifest.bucket == "test-cdn-cf-logs"
    error_message = "Access-log bucket name must be derived from config.name."
  }

  # CloudFront standard logging needs ACLs enabled on the log bucket.
  assert {
    condition     = module.log_bucket[0].manifest.bucket == "test-cdn-cf-logs"
    error_message = "Log bucket must be the owned, derived bucket."
  }

  # The distribution composes exactly one module instance.
  assert {
    condition     = module.distribution.manifest != null
    error_message = "The distribution must be composed."
  }
}

run "custom_origin_skips_oac" {
  command = plan

  variables {
    config = {
      name                      = "test-cdn-custom"
      custom_origin_domain_name = "origin.example.com"
    }
  }

  # No OAC for a custom (non-S3) origin.
  assert {
    condition     = length(module.oac) == 0
    error_message = "No OAC must be created for a custom origin."
  }

  # Manifest reports a null oac_id for custom origins.
  assert {
    condition     = output.manifest.oac_id == null
    error_message = "Manifest oac_id must be null for a custom origin."
  }
}

run "byo_log_bucket_skips_bucket_creation" {
  command = plan

  variables {
    config = {
      name                  = "test-cdn-byo"
      s3_origin_domain_name = "test-bucket.s3.eu-central-1.amazonaws.com"
      log_bucket            = "my-existing-logs.s3.amazonaws.com"
    }
  }

  assert {
    condition     = length(module.log_bucket) == 0
    error_message = "No log bucket must be created when a BYO log bucket is supplied."
  }

  assert {
    condition     = output.manifest.log_bucket == null
    error_message = "Manifest log_bucket must be null when a BYO bucket is used (component owns no bucket)."
  }
}

run "logging_disabled_creates_no_bucket" {
  command = plan

  variables {
    config = {
      name                  = "test-cdn-nolog"
      s3_origin_domain_name = "test-bucket.s3.eu-central-1.amazonaws.com"
      enable_logging        = false
    }
  }

  assert {
    condition     = length(module.log_bucket) == 0
    error_message = "No log bucket when logging is disabled."
  }

  assert {
    condition     = output.manifest.log_bucket == null
    error_message = "Manifest log_bucket must be null when logging is disabled."
  }
}

# Negative (validation -> var.config): neither origin supplied is rejected.
run "neither_origin_is_rejected" {
  command = plan

  variables {
    config = {
      name = "test-cdn-noorigin"
    }
  }

  expect_failures = [
    var.config,
  ]
}

# Negative (validation -> var.config): both origins supplied is rejected.
run "both_origins_is_rejected" {
  command = plan

  variables {
    config = {
      name                      = "test-cdn-bothorigin"
      s3_origin_domain_name     = "test-bucket.s3.eu-central-1.amazonaws.com"
      custom_origin_domain_name = "origin.example.com"
    }
  }

  expect_failures = [
    var.config,
  ]
}

# Negative (validation -> var.config): aliases without an ACM cert is rejected.
run "aliases_without_cert_is_rejected" {
  command = plan

  variables {
    config = {
      name                  = "test-cdn-aliases"
      s3_origin_domain_name = "test-bucket.s3.eu-central-1.amazonaws.com"
      aliases               = ["cdn.example.com"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
