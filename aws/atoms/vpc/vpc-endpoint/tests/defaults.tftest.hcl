# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the endpoint atom's secure defaults.
# ARNs/ids are unknown under the mock provider, so assertions target known,
# derived values (the resolved arguments) plus plan success.

mock_provider "aws" {}

run "interface_defaults" {
  command = plan

  variables {
    config = {
      vpc_id             = "vpc-0123456789abcdef0"
      service_name       = "com.amazonaws.eu-central-1.secretsmanager"
      subnet_ids         = ["subnet-aaaa", "subnet-bbbb"]
      security_group_ids = ["sg-aaaa"]
    }
  }

  # Defaults to an Interface endpoint.
  assert {
    condition     = aws_vpc_endpoint.this.vpc_endpoint_type == "Interface"
    error_message = "Endpoint type must default to Interface."
  }

  # Private DNS is ON by default so the public service name resolves privately
  # and traffic stays off the internet (PCI DSS Req 1 segmentation).
  assert {
    condition     = aws_vpc_endpoint.this.private_dns_enabled == true
    error_message = "Interface endpoints must default to private_dns_enabled = true."
  }

  assert {
    condition     = aws_vpc_endpoint.this.service_name == "com.amazonaws.eu-central-1.secretsmanager"
    error_message = "service_name must be passed through unchanged."
  }
}

run "gateway_attaches_route_tables_and_disables_private_dns" {
  command = plan

  variables {
    config = {
      vpc_id            = "vpc-0123456789abcdef0"
      service_name      = "com.amazonaws.eu-central-1.s3"
      vpc_endpoint_type = "Gateway"
      route_table_ids   = ["rtb-aaaa", "rtb-bbbb"]
    }
  }

  assert {
    condition     = aws_vpc_endpoint.this.vpc_endpoint_type == "Gateway"
    error_message = "Endpoint type must be Gateway."
  }

  # Gateway endpoints attach to route tables...
  assert {
    condition     = length(aws_vpc_endpoint.this.route_table_ids) == 2
    error_message = "Gateway endpoint must attach to the supplied route tables."
  }

  # ...and private DNS is forced off (AWS rejects it on non-Interface types).
  # The local computes null for non-Interface types; assert on the source-of-
  # truth local rather than the resource attribute, which the mock provider
  # fills with an unknown bool at plan time.
  assert {
    condition     = local.private_dns_enabled == null
    error_message = "private_dns_enabled must be null for non-Interface endpoints."
  }
}

# Negative: an Interface endpoint with no security groups is blocked by the
# atom's lifecycle precondition (unscoped ENI access).
run "interface_without_sg_is_blocked" {
  command = plan

  variables {
    config = {
      vpc_id       = "vpc-0123456789abcdef0"
      service_name = "com.amazonaws.eu-central-1.secretsmanager"
      subnet_ids   = ["subnet-aaaa"]
      # security_group_ids intentionally omitted
    }
  }

  expect_failures = [
    aws_vpc_endpoint.this,
  ]
}

# Negative: an invalid endpoint type is rejected by config validation.
run "invalid_type_is_rejected" {
  command = plan

  variables {
    config = {
      vpc_id            = "vpc-0123456789abcdef0"
      service_name      = "com.amazonaws.eu-central-1.s3"
      vpc_endpoint_type = "NotAType"
    }
  }

  expect_failures = [
    var.config,
  ]
}
