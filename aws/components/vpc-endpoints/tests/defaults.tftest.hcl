# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the secure-by-default composition.
# Child modules expose only their `manifest` (not their `config`), and ids/ARNs
# are unknown under a mock — so assertions target known values: child-module
# instance counts (which prove the wiring), the component's own manifest keys,
# and plan success. data.aws_region and data.aws_vpc are overridden so the
# region prefix and VPC CIDR are deterministic and valid.

mock_provider "aws" {}

override_data {
  target = data.aws_region.current
  values = {
    name = "eu-central-1"
  }
}

override_data {
  target = data.aws_vpc.this
  values = {
    cidr_block = "10.0.0.0/16"
  }
}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      vpc_id                  = "vpc-0123456789abcdef0"
      private_subnet_ids      = ["subnet-aaaa", "subnet-bbbb"]
      private_route_table_ids = ["rtb-aaaa"]
    }
  }

  # The endpoint security group is created.
  assert {
    condition     = can(output.manifest.security_group_id)
    error_message = "manifest must expose the endpoint security_group_id."
  }

  # Two gateway endpoints (s3, dynamodb) by default.
  assert {
    condition     = length(module.gateway_endpoint) == 2
    error_message = "The default two Gateway endpoints (s3, dynamodb) must be created."
  }

  # Ten interface endpoints by default.
  assert {
    condition     = length(module.interface_endpoint) == 10
    error_message = "The default ten Interface endpoints must be created."
  }

  # The plan succeeding is itself the proof of correct wiring: the vpc-endpoint
  # atom's preconditions FAIL the plan unless every Interface endpoint receives
  # a security group and every Gateway endpoint receives route tables. So a
  # clean plan with both kinds present means the component attached the endpoint
  # SG to the interface endpoints (with private_dns_enabled ON) and the route
  # tables to the gateway endpoints.

  # Manifest maps short names to ids, split by kind and combined.
  assert {
    condition     = contains(keys(output.manifest.gateway_endpoint_ids), "s3") && contains(keys(output.manifest.gateway_endpoint_ids), "dynamodb")
    error_message = "manifest.gateway_endpoint_ids must be keyed by short service name."
  }

  assert {
    condition     = contains(keys(output.manifest.interface_endpoint_ids), "secretsmanager") && contains(keys(output.manifest.interface_endpoint_ids), "ecr.api")
    error_message = "manifest.interface_endpoint_ids must be keyed by short service name."
  }

  assert {
    condition     = length(keys(output.manifest.endpoint_ids)) == 12
    error_message = "manifest.endpoint_ids must combine all gateway and interface endpoint ids."
  }
}

# Gateway endpoints can be disabled (interface-only deployment).
run "interface_only" {
  command = plan

  variables {
    config = {
      vpc_id             = "vpc-0123456789abcdef0"
      private_subnet_ids = ["subnet-aaaa"]
      gateway_services   = []
      interface_services = ["secretsmanager", "kms"]
    }
  }

  assert {
    condition     = length(module.gateway_endpoint) == 0 && length(module.interface_endpoint) == 2
    error_message = "With gateway_services=[] only the requested interface endpoints are created."
  }
}

# Negative: requesting interface endpoints without private subnets violates the
# paired validation on var.config.
run "interface_endpoints_require_subnets" {
  command = plan

  variables {
    config = {
      vpc_id = "vpc-0123456789abcdef0"
      # private_subnet_ids omitted while interface_services keeps its default
      private_route_table_ids = ["rtb-aaaa"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
