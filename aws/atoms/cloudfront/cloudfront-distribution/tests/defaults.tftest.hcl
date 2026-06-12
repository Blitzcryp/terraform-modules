# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the distribution atom's secure-by-default
# behaviour. Under mock_provider, computed attributes (arn, domain_name, status)
# are unknown, so we assert on known/derived inputs and on plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      comment = "test distribution"
      origins = [
        {
          domain_name              = "test-bucket.s3.eu-central-1.amazonaws.com"
          origin_id                = "s3-test"
          origin_access_control_id = "E1TESTOAC1"
          s3_origin_config         = {}
        }
      ]
      default_cache_behavior = {
        target_origin_id = "s3-test"
        cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      }
    }
  }

  # PCI Req 4: viewers are redirected to HTTPS by default.
  assert {
    condition     = aws_cloudfront_distribution.this.default_cache_behavior[0].viewer_protocol_policy == "redirect-to-https"
    error_message = "Default viewer_protocol_policy must be redirect-to-https (PCI DSS Req 4)."
  }

  # PCI Req 4: TLS floor is 1.2_2021 (effective once a custom cert is attached).
  assert {
    condition     = var.config.minimum_protocol_version == "TLSv1.2_2021"
    error_message = "minimum_protocol_version must default to TLSv1.2_2021."
  }

  # Default root object hardening.
  assert {
    condition     = aws_cloudfront_distribution.this.default_root_object == "index.html"
    error_message = "default_root_object must default to index.html."
  }

  # OAC is wired onto the origin (private S3 origin locked to CloudFront).
  assert {
    condition     = one(aws_cloudfront_distribution.this.origin).origin_access_control_id == "E1TESTOAC1"
    error_message = "The OAC id must be attached to the S3 origin."
  }

  # Default cert path: no aliases, default CloudFront cert used.
  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].cloudfront_default_certificate == true
    error_message = "Without an ACM cert the default CloudFront certificate must be used."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.enabled == true
    error_message = "Distribution must default to enabled."
  }
}

run "acm_cert_with_aliases_uses_strong_tls" {
  command = plan

  variables {
    config = {
      aliases             = ["cdn.example.com"]
      acm_certificate_arn = "arn:aws:acm:us-east-1:111122223333:certificate/abcd1234-ab12-cd34-ef56-abcdef123456"
      origins = [
        {
          domain_name          = "origin.example.com"
          origin_id            = "custom-test"
          custom_origin_config = {}
        }
      ]
      default_cache_behavior = {
        target_origin_id = "custom-test"
        cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      }
    }
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].minimum_protocol_version == "TLSv1.2_2021"
    error_message = "With a custom ACM cert the TLS floor must be TLSv1.2_2021."
  }

  assert {
    condition     = aws_cloudfront_distribution.this.viewer_certificate[0].cloudfront_default_certificate == false
    error_message = "With a custom ACM cert the default CloudFront certificate must be disabled."
  }
}

# Negative (validation -> var.config): allow-all viewer protocol without the
# escape hatch is rejected at plan time (PCI DSS Req 4).
run "allow_all_viewer_protocol_is_rejected" {
  command = plan

  variables {
    config = {
      origins = [
        {
          domain_name          = "origin.example.com"
          origin_id            = "custom-test"
          custom_origin_config = {}
        }
      ]
      default_cache_behavior = {
        target_origin_id       = "custom-test"
        viewer_protocol_policy = "allow-all"
        cache_policy_id        = "658327ea-f89d-4fab-a63d-7e88639e58f6"
        # allow_insecure_viewer intentionally left at its false default
      }
    }
  }

  expect_failures = [
    var.config,
  ]
}

# Negative (validation -> var.config): aliases without an ACM cert are rejected.
run "aliases_without_cert_is_rejected" {
  command = plan

  variables {
    config = {
      aliases = ["cdn.example.com"]
      origins = [
        {
          domain_name          = "origin.example.com"
          origin_id            = "custom-test"
          custom_origin_config = {}
        }
      ]
      default_cache_behavior = {
        target_origin_id = "custom-test"
        cache_policy_id  = "658327ea-f89d-4fab-a63d-7e88639e58f6"
      }
    }
  }

  expect_failures = [
    var.config,
  ]
}
