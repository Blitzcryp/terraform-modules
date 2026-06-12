# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the network ACL atom's secure-by-default
# (default-deny, explicit numbered rules) behaviour. ARNs/ids are unknown under
# the mock, so assertions target known values: rule resource counts, the rule
# fields fed in, and plan success/failure.

mock_provider "aws" {}

run "explicit_rules_plan_succeeds" {
  command = plan

  variables {
    config = {
      vpc_id     = "vpc-12345678"
      name       = "test-nacl"
      subnet_ids = ["subnet-aaaa1111"]
      ingress_rules = [
        {
          rule_number = 100
          protocol    = "tcp"
          rule_action = "allow"
          cidr_block  = "10.0.0.0/16"
          from_port   = 443
          to_port     = 443
        },
        {
          rule_number = 110
          protocol    = "tcp"
          rule_action = "allow"
          cidr_block  = "10.0.0.0/16"
          from_port   = 1024
          to_port     = 65535
        },
      ]
      egress_rules = [
        {
          rule_number = 100
          protocol    = "tcp"
          rule_action = "allow"
          cidr_block  = "10.0.0.0/16"
          from_port   = 443
          to_port     = 443
        },
      ]
    }
  }

  # The two ingress and one egress rules are created as separate resources.
  assert {
    condition     = length(aws_network_acl_rule.ingress) == 2
    error_message = "Expected exactly two ingress rules to be created."
  }

  assert {
    condition     = length(aws_network_acl_rule.egress) == 1
    error_message = "Expected exactly one egress rule to be created."
  }

  # The ingress rules are tagged as ingress (egress=false), egress as egress=true.
  assert {
    condition     = alltrue([for r in aws_network_acl_rule.ingress : r.egress == false])
    error_message = "Ingress rules must set egress=false."
  }

  assert {
    condition     = alltrue([for r in aws_network_acl_rule.egress : r.egress == true])
    error_message = "Egress rules must set egress=true."
  }

  # The subnet association is carried onto the NACL.
  assert {
    condition     = contains(aws_network_acl.this.subnet_ids, "subnet-aaaa1111")
    error_message = "Subnet association must be passed to the network ACL."
  }
}

run "no_rules_is_default_deny" {
  command = plan

  variables {
    config = {
      vpc_id = "vpc-12345678"
      # No rules at all — the NACL denies everything (default-deny).
    }
  }

  assert {
    condition     = length(aws_network_acl_rule.ingress) == 0 && length(aws_network_acl_rule.egress) == 0
    error_message = "A NACL with no configured rules must create no rule resources (default-deny)."
  }
}

run "public_ssh_allow_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      vpc_id = "vpc-12345678"
      ingress_rules = [
        {
          rule_number = 100
          protocol    = "tcp"
          rule_action = "allow"
          cidr_block  = "0.0.0.0/0"
          from_port   = 22
          to_port     = 22
        },
      ]
      # allow_public_admin_ports and allow_public_ingress intentionally false.
    }
  }

  expect_failures = [
    aws_network_acl.this,
  ]
}

run "public_ssh_allow_permitted_with_escape_hatches" {
  command = plan

  variables {
    config = {
      vpc_id = "vpc-12345678"
      ingress_rules = [
        {
          rule_number = 100
          protocol    = "tcp"
          rule_action = "allow"
          cidr_block  = "0.0.0.0/0"
          from_port   = 22
          to_port     = 22
        },
      ]
      allow_public_ingress     = true
      allow_public_admin_ports = true
    }
  }

  assert {
    condition     = length(aws_network_acl_rule.ingress) == 1
    error_message = "With both escape hatches flipped, the public admin rule must plan successfully."
  }
}

run "invalid_rule_action_is_rejected" {
  command = plan

  variables {
    config = {
      vpc_id = "vpc-12345678"
      ingress_rules = [
        {
          rule_number = 100
          protocol    = "tcp"
          rule_action = "permit" # not "allow"/"deny"
          cidr_block  = "10.0.0.0/16"
          from_port   = 443
          to_port     = 443
        },
      ]
    }
  }

  expect_failures = [
    var.config,
  ]
}

run "tcp_rule_without_ports_is_rejected" {
  command = plan

  variables {
    config = {
      vpc_id = "vpc-12345678"
      ingress_rules = [
        {
          rule_number = 100
          protocol    = "tcp"
          rule_action = "allow"
          cidr_block  = "10.0.0.0/16"
          # from_port/to_port omitted — invalid for tcp.
        },
      ]
    }
  }

  expect_failures = [
    var.config,
  ]
}
