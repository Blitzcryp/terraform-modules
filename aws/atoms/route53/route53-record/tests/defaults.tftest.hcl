# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. fqdn/id are unknown under the mock provider, so
# assertions target the known/derived input values and the alias-vs-standard
# branching.

mock_provider "aws" {}

run "standard_record_defaults" {
  command = plan

  variables {
    config = {
      zone_id = "Z01234567ABCDEFGHIJK"
      name    = "app.example.com"
      type    = "A"
      records = ["203.0.113.10"]
    }
  }

  assert {
    condition     = aws_route53_record.this.ttl == 300
    error_message = "ttl must default to 300 for standard records."
  }

  assert {
    condition     = aws_route53_record.this.allow_overwrite == false
    error_message = "allow_overwrite must default to false (do not clobber existing records)."
  }

  assert {
    condition     = length(aws_route53_record.this.alias) == 0
    error_message = "No alias block must be set for a standard record."
  }
}

run "alias_record_omits_ttl_and_records" {
  command = plan

  variables {
    config = {
      zone_id = "Z01234567ABCDEFGHIJK"
      name    = "example.com"
      type    = "A"
      alias = {
        name    = "dualstack.my-alb-1234567890.eu-central-1.elb.amazonaws.com"
        zone_id = "Z215JYRZR1TBD5"
      }
    }
  }

  assert {
    condition     = length(aws_route53_record.this.alias) == 1
    error_message = "An alias block must be set for an alias record."
  }

  assert {
    condition     = aws_route53_record.this.ttl == null
    error_message = "ttl must be null for an alias record."
  }
}

# --- Negative case: an unsupported record type is rejected by config validation. ---
run "invalid_record_type_is_rejected" {
  command = plan

  variables {
    config = {
      zone_id = "Z01234567ABCDEFGHIJK"
      name    = "app.example.com"
      type    = "INVALID"
      records = ["203.0.113.10"]
    }
  }

  expect_failures = [
    var.config,
  ]
}

# --- Negative case: neither records nor alias is rejected by config validation. ---
run "neither_records_nor_alias_is_rejected" {
  command = plan

  variables {
    config = {
      zone_id = "Z01234567ABCDEFGHIJK"
      name    = "app.example.com"
      type    = "A"
    }
  }

  expect_failures = [
    var.config,
  ]
}
