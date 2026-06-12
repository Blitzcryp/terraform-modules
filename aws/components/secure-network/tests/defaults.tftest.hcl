# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the secure-by-default composition.
# Child modules expose only their `manifest` (not their `config`) to tests, and
# ARNs are unknown under a mock provider — so assertions target known values:
# child-module instance counts (which prove the conditional wiring), the
# component's own manifest keys, and plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name       = "test-net"
      cidr_block = "10.0.0.0/16"
      subnets = [
        {
          name              = "private-a"
          cidr_block        = "10.0.1.0/24"
          availability_zone = "eu-central-1a"
        },
        {
          name              = "private-b"
          cidr_block        = "10.0.2.0/24"
          availability_zone = "eu-central-1b"
        },
      ]
    }
  }

  # Flow logs default ON and are self-provisioned: the trio is created.
  assert {
    condition     = length(module.flow_log_kms) == 1
    error_message = "Flow-log KMS key must be self-provisioned by default."
  }

  assert {
    condition     = length(module.flow_log_group) == 1
    error_message = "Flow-log CloudWatch log group must be self-provisioned by default."
  }

  assert {
    condition     = length(module.flow_log_role) == 1
    error_message = "Flow-log delivery IAM role must be self-provisioned by default."
  }

  # Both subnets are created and keyed by name.
  assert {
    condition     = length(module.subnet) == 2
    error_message = "Both subnets must be created."
  }

  # The manifest exposes a subnet id per subnet name, and a list of ids.
  assert {
    condition     = length(keys(output.manifest.subnet_ids_by_name)) == 2 && contains(keys(output.manifest.subnet_ids_by_name), "private-a") && contains(keys(output.manifest.subnet_ids_by_name), "private-b")
    error_message = "manifest.subnet_ids_by_name must map every subnet name to an id."
  }

  assert {
    condition     = length(output.manifest.subnet_ids) == 2
    error_message = "manifest.subnet_ids must list every subnet id."
  }

  # The manifest exposes the flow-log keys (their ARNs are unknown under the
  # mock provider; the trio-count asserts above prove self-provisioning).
  assert {
    condition     = can(output.manifest.flow_log_destination_arn) && can(output.manifest.flow_log_role_arn)
    error_message = "manifest must expose flow_log_destination_arn and flow_log_role_arn."
  }

  # Private-only network: no internet gateway, no NAT, no public route table.
  # A single shared private route table is created (with no egress route since
  # there is no NAT), associated to both private subnets.
  assert {
    condition     = length(module.internet_gateway) == 0 && length(module.nat_gateway) == 0
    error_message = "A private-only network must not create an internet or NAT gateway."
  }

  assert {
    condition     = output.manifest.internet_gateway_id == null && length(output.manifest.nat_gateway_ids) == 0 && output.manifest.public_route_table_id == null
    error_message = "Routing manifest keys must reflect a private-only network (no IGW/NAT/public RT)."
  }

  assert {
    condition     = length(module.private_route_table) == 1 && length(output.manifest.private_route_table_ids) == 1
    error_message = "A private-only network must have a single shared private route table."
  }
}

run "public_subnet_flips_escape_hatch" {
  command = plan

  variables {
    config = {
      name       = "test-net"
      cidr_block = "10.0.0.0/16"
      subnets = [
        {
          name              = "public-a"
          cidr_block        = "10.0.1.0/24"
          availability_zone = "eu-central-1a"
          public            = true
        },
      ]
    }
  }

  # A public subnet still plans cleanly and is keyed by name in the manifest.
  # (The subnet atom only accepts map_public_ip_on_launch=true when its
  # allow_auto_public_ip escape hatch is also true; this run proves the
  # component sets both together — otherwise the atom precondition would fail.)
  assert {
    condition     = contains(keys(output.manifest.subnet_ids_by_name), "public-a")
    error_message = "Public subnet must be created and present in the manifest."
  }
}

run "byo_sink_skips_self_provisioning" {
  command = plan

  variables {
    config = {
      name       = "test-net"
      cidr_block = "10.0.0.0/16"
      subnets = [
        {
          name              = "private-a"
          cidr_block        = "10.0.1.0/24"
          availability_zone = "eu-central-1a"
        },
      ]
      byo_flow_log_destination_arn = "arn:aws:logs:eu-central-1:111122223333:log-group:central-flow-logs"
      byo_flow_log_role_arn        = "arn:aws:iam::111122223333:role/central-flow-logs"
    }
  }

  # With BOTH BYO ARNs supplied, none of the trio is created.
  assert {
    condition     = length(module.flow_log_kms) == 0 && length(module.flow_log_group) == 0 && length(module.flow_log_role) == 0
    error_message = "BYO flow-log sink must skip self-provisioning the kms/log-group/iam-role trio."
  }

  # The BYO ARNs surface unchanged on the manifest.
  assert {
    condition     = output.manifest.flow_log_destination_arn == "arn:aws:logs:eu-central-1:111122223333:log-group:central-flow-logs"
    error_message = "BYO destination ARN must be passed through to the manifest."
  }

  assert {
    condition     = output.manifest.flow_log_role_arn == "arn:aws:iam::111122223333:role/central-flow-logs"
    error_message = "BYO role ARN must be passed through to the manifest."
  }
}

# Negative case: a single BYO ARN (without its partner) violates the paired
# validation on var.config.
run "byo_arns_must_be_paired" {
  command = plan

  variables {
    config = {
      name       = "test-net"
      cidr_block = "10.0.0.0/16"
      subnets = [
        {
          name              = "private-a"
          cidr_block        = "10.0.1.0/24"
          availability_zone = "eu-central-1a"
        },
      ]
      byo_flow_log_destination_arn = "arn:aws:logs:eu-central-1:111122223333:log-group:central-flow-logs"
      # byo_flow_log_role_arn intentionally omitted
    }
  }

  expect_failures = [
    var.config,
  ]
}

# --- Routing -----------------------------------------------------------------

# A public + private subnet (defaults: nat_gateway_mode="single") yields an
# internet gateway, ONE NAT (+ its EIP), a public route table and one shared
# private route table.
run "public_and_private_creates_full_routing" {
  command = plan

  variables {
    config = {
      name       = "test-net"
      cidr_block = "10.0.0.0/16"
      subnets = [
        {
          name              = "public-a"
          cidr_block        = "10.0.0.0/24"
          availability_zone = "eu-central-1a"
          public            = true
        },
        {
          name              = "private-a"
          cidr_block        = "10.0.1.0/24"
          availability_zone = "eu-central-1a"
        },
        {
          name              = "private-b"
          cidr_block        = "10.0.2.0/24"
          availability_zone = "eu-central-1b"
        },
      ]
    }
  }

  assert {
    condition     = length(module.internet_gateway) == 1
    error_message = "A public subnet must trigger an internet gateway."
  }

  assert {
    condition     = length(module.nat_gateway) == 1 && length(module.nat_eip) == 1
    error_message = "nat_gateway_mode='single' (default) must create exactly one NAT gateway and one EIP."
  }

  assert {
    condition     = length(module.public_route_table) == 1
    error_message = "A public route table must be created when there are public subnets and an IGW."
  }

  assert {
    condition     = length(module.private_route_table) == 1
    error_message = "nat_gateway_mode='single' must use one shared private route table."
  }

  # ARNs/ids are unknown under the mock provider, so assert on the known list
  # cardinalities (counts of NAT and private route tables) and the presence of
  # the manifest keys; the module-instance-count asserts above prove IGW/public
  # RT creation.
  assert {
    condition     = length(output.manifest.nat_gateway_ids) == 1 && length(output.manifest.private_route_table_ids) == 1
    error_message = "Routing manifest must list 1 NAT gateway and 1 private route table."
  }

  assert {
    condition     = can(output.manifest.internet_gateway_id) && can(output.manifest.public_route_table_id)
    error_message = "Routing manifest must expose internet_gateway_id and public_route_table_id."
  }
}

# nat_gateway_mode="per_az": one NAT per AZ that has a public subnet, and a
# private route table per AZ.
run "per_az_nat_creates_one_nat_and_rt_per_az" {
  command = plan

  variables {
    config = {
      name             = "test-net"
      cidr_block       = "10.0.0.0/16"
      nat_gateway_mode = "per_az"
      subnets = [
        {
          name              = "public-a"
          cidr_block        = "10.0.0.0/24"
          availability_zone = "eu-central-1a"
          public            = true
        },
        {
          name              = "public-b"
          cidr_block        = "10.0.1.0/24"
          availability_zone = "eu-central-1b"
          public            = true
        },
        {
          name              = "private-a"
          cidr_block        = "10.0.2.0/24"
          availability_zone = "eu-central-1a"
        },
        {
          name              = "private-b"
          cidr_block        = "10.0.3.0/24"
          availability_zone = "eu-central-1b"
        },
      ]
    }
  }

  assert {
    condition     = length(module.nat_gateway) == 2 && length(module.nat_eip) == 2
    error_message = "nat_gateway_mode='per_az' must create one NAT (and EIP) per public AZ."
  }

  assert {
    condition     = length(module.private_route_table) == 2 && length(output.manifest.private_route_table_ids) == 2
    error_message = "nat_gateway_mode='per_az' must create a private route table per AZ."
  }
}

# nat_gateway_mode="none": IGW + public route table still created, but no NAT
# and the private route table carries no egress route.
run "nat_none_skips_nat_keeps_igw" {
  command = plan

  variables {
    config = {
      name             = "test-net"
      cidr_block       = "10.0.0.0/16"
      nat_gateway_mode = "none"
      subnets = [
        {
          name              = "public-a"
          cidr_block        = "10.0.0.0/24"
          availability_zone = "eu-central-1a"
          public            = true
        },
        {
          name              = "private-a"
          cidr_block        = "10.0.1.0/24"
          availability_zone = "eu-central-1a"
        },
      ]
    }
  }

  assert {
    condition     = length(module.nat_gateway) == 0 && length(module.nat_eip) == 0
    error_message = "nat_gateway_mode='none' must not create any NAT gateway or EIP."
  }

  assert {
    condition     = length(module.internet_gateway) == 1 && length(module.public_route_table) == 1
    error_message = "nat_gateway_mode='none' must still create the IGW and public route table for the public subnet."
  }

  assert {
    condition     = length(output.manifest.nat_gateway_ids) == 0
    error_message = "manifest.nat_gateway_ids must be empty when nat_gateway_mode='none'."
  }
}

# nat_gateway_mode='single' on a private-only network is a graceful no-op:
# no public subnet means no NAT (and no IGW) — same effective topology as
# 'none'. This preserves backward compatibility for callers that pass only
# private subnets while leaving nat_gateway_mode at its "single" default.
run "nat_single_private_only_creates_no_nat" {
  command = plan

  variables {
    config = {
      name             = "test-net"
      cidr_block       = "10.0.0.0/16"
      nat_gateway_mode = "single"
      subnets = [
        {
          name              = "private-a"
          cidr_block        = "10.0.1.0/24"
          availability_zone = "eu-central-1a"
        },
      ]
    }
  }

  assert {
    condition     = length(module.nat_gateway) == 0 && length(module.internet_gateway) == 0
    error_message = "A private-only network must create no NAT and no IGW even at the default nat_gateway_mode='single'."
  }
}

# Requesting NAT against a public subnet while explicitly disabling the IGW is
# unroutable and must be rejected.
run "nat_with_disabled_igw_is_rejected" {
  command = plan

  variables {
    config = {
      name                    = "test-net"
      cidr_block              = "10.0.0.0/16"
      nat_gateway_mode        = "single"
      enable_internet_gateway = false
      subnets = [
        {
          name              = "public-a"
          cidr_block        = "10.0.0.0/24"
          availability_zone = "eu-central-1a"
          public            = true
        },
      ]
    }
  }

  expect_failures = [
    var.config,
  ]
}
