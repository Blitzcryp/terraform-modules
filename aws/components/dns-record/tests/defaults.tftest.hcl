# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. fqdn/id are unknown under the mock provider, so
# assertions target known/derived values (module counts) and config validation.

mock_provider "aws" {}

run "creates_one_atom_per_record" {
  command = plan

  variables {
    config = {
      zone_id = "Z01234567ABCDEFGHIJK"
      records = [
        {
          name = "example.com"
          type = "A"
          alias = {
            name    = "dualstack.my-alb-1234567890.eu-central-1.elb.amazonaws.com"
            zone_id = "Z215JYRZR1TBD5"
          }
        },
        {
          name   = "docs.example.com"
          type   = "CNAME"
          values = ["my-docs-site.example.net"]
        },
      ]
    }
  }

  assert {
    condition     = length(module.record) == 2
    error_message = "One route53-record atom must be created per requested record."
  }
}

run "single_standard_record" {
  command = plan

  variables {
    config = {
      zone_id = "Z01234567ABCDEFGHIJK"
      records = [
        {
          name   = "app.example.com"
          values = ["203.0.113.10"]
        },
      ]
    }
  }

  assert {
    condition     = length(module.record) == 1
    error_message = "A single standard record must create exactly one atom."
  }
}

# --- Negative case: a record with neither values nor alias is rejected. ---
run "record_without_values_or_alias_is_rejected" {
  command = plan

  variables {
    config = {
      zone_id = "Z01234567ABCDEFGHIJK"
      records = [
        {
          name = "app.example.com"
          type = "A"
        },
      ]
    }
  }

  expect_failures = [
    var.config,
  ]
}

# --- Negative case: an empty records list is rejected. ---
run "empty_records_is_rejected" {
  command = plan

  variables {
    config = {
      zone_id = "Z01234567ABCDEFGHIJK"
      records = []
    }
  }

  expect_failures = [
    var.config,
  ]
}
