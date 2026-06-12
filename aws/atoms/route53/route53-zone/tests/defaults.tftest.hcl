# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults_public_zone_query_logging" {
  command = plan

  variables {
    config = {
      name                      = "example.emag.internal"
      query_log_destination_arn = "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/example:*"
    }
  }

  # Query logging resource must be created for a public zone with a destination.
  assert {
    condition     = length(aws_route53_query_log.this) == 1
    error_message = "Public zone with a destination must enable DNS query logging (PCI DSS Req 10)."
  }

  assert {
    condition     = aws_route53_query_log.this[0].cloudwatch_log_group_arn == "arn:aws:logs:us-east-1:123456789012:log-group:/aws/route53/example:*"
    error_message = "Query log destination ARN must be wired into aws_route53_query_log."
  }

  assert {
    condition     = aws_route53_zone.this.force_destroy == false
    error_message = "force_destroy must default to false."
  }
}

run "private_zone_skips_query_logging" {
  command = plan

  variables {
    config = {
      name         = "internal.emag.local"
      private_zone = true
      vpc_ids      = ["vpc-0123456789abcdef0"]
    }
  }

  # Private zones cannot query-log; resource is skipped and precondition is N/A.
  assert {
    condition     = length(aws_route53_query_log.this) == 0
    error_message = "Private zones must not create a query log resource."
  }
}

run "public_zone_without_logging_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      name = "example.emag.internal"
      # no query_log_destination_arn, allow_query_logging_disabled left false
    }
  }

  expect_failures = [
    aws_route53_zone.this,
  ]
}

run "private_zone_requires_vpc_ids" {
  command = plan

  variables {
    config = {
      name         = "internal.emag.local"
      private_zone = true
      # vpc_ids intentionally empty
    }
  }

  expect_failures = [
    var.config,
  ]
}
