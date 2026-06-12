# Native `terraform test` for the secure-landing-zone blueprint. Uses a mocked
# AWS provider so no credentials or real resources are needed. Under the mock,
# computed ARNs/ids are unknown, so we assert on known/derived values: per-
# capability module instance counts (tracking the enable flags) and manifest
# nullness. Plan success is asserted by the run itself.

mock_provider "aws" {}

# The composed components read region/partition/account-id via their own data
# sources, and several derive ARNs (CloudTrail bucket policy, Config bucket
# policy, Security Hub standards) from them. Under mock_provider these would be
# random strings that fail provider-side validation, so pin them on every
# component (and the nested atoms that read their own identity).
override_data {
  target = module.audit_logging[0].data.aws_region.current
  values = { name = "eu-central-1" }
}
override_data {
  target = module.audit_logging[0].data.aws_caller_identity.current
  values = { account_id = "111122223333" }
}

override_data {
  target = module.cloudtrail[0].data.aws_region.current
  values = { name = "eu-central-1" }
}
override_data {
  target = module.cloudtrail[0].data.aws_caller_identity.current
  values = { account_id = "111122223333" }
}
override_data {
  target = module.cloudtrail[0].data.aws_partition.current
  values = { partition = "aws" }
}

override_data {
  target = module.cspm[0].data.aws_region.current
  values = { name = "eu-central-1" }
}
override_data {
  target = module.cspm[0].data.aws_partition.current
  values = { partition = "aws" }
}
override_data {
  target = module.cspm[0].data.aws_caller_identity.current
  values = { account_id = "111122223333" }
}
override_data {
  target = module.cspm[0].module.security_hub[0].data.aws_region.current
  values = { name = "eu-central-1" }
}
override_data {
  target = module.cspm[0].module.security_hub[0].data.aws_partition.current
  values = { partition = "aws" }
}
override_data {
  target = module.cspm[0].module.inspector[0].data.aws_caller_identity.current
  values = { account_id = "111122223333" }
}

override_data {
  target = module.findings_notification[0].data.aws_caller_identity.current
  values = { account_id = "111122223333" }
}

variables {
  base = {
    name_prefix = "test-lz"
  }
}

# --- Defaults: the full baseline is composed, no network ----------------------
run "defaults_compose_baseline" {
  command = plan

  variables {
    config = var.base
  }

  # Default-on capabilities are each composed exactly once.
  assert {
    condition     = length(module.account_baseline) == 1
    error_message = "account-baseline must be composed by default."
  }
  assert {
    condition     = length(module.audit_logging) == 1
    error_message = "audit-logging must be composed by default."
  }
  assert {
    condition     = length(module.cloudtrail) == 1
    error_message = "cloudtrail must be composed by default."
  }
  assert {
    condition     = length(module.cspm) == 1
    error_message = "cspm must be composed by default."
  }
  assert {
    condition     = length(module.findings_notification) == 1
    error_message = "findings-notification must be composed by default."
  }

  # Network is OFF by default; the manifest vpc_id is null.
  assert {
    condition     = length(module.network) == 0
    error_message = "secure-network must not be composed when enable_network = false (default)."
  }
  assert {
    condition     = output.manifest.vpc_id == null
    error_message = "manifest.vpc_id must be null when no network is created."
  }

  # Password policy minimum length defaults to 14 and surfaces on the manifest.
  assert {
    condition     = output.manifest.password_policy_min_length == 14
    error_message = "Default password policy minimum length must be 14 and surface on the manifest."
  }
}

# --- Network enabled: secure-network composed, vpc_id wired -------------------
run "network_enabled" {
  command = plan

  variables {
    config = {
      name_prefix    = "test-lz-net"
      enable_network = true
      vpc_cidr       = "10.60.0.0/16"
      subnets = [
        { name = "private-a", cidr_block = "10.60.10.0/24", availability_zone = "eu-central-1a" },
        { name = "public-a", cidr_block = "10.60.0.0/24", availability_zone = "eu-central-1a", public = true },
      ]
    }
  }

  override_data {
    target = module.network[0].data.aws_region.current
    values = { name = "eu-central-1" }
  }
  override_data {
    target = module.network[0].data.aws_caller_identity.current
    values = { account_id = "111122223333" }
  }

  assert {
    condition     = length(module.network) == 1
    error_message = "secure-network must be composed when enable_network = true."
  }
}

# --- A capability toggled off: count 0 and manifest key null ------------------
run "capability_toggled_off" {
  command = plan

  variables {
    config = {
      name_prefix                  = "test-lz-off"
      enable_account_baseline      = false
      enable_cloudtrail            = false
      enable_findings_notification = false
    }
  }

  assert {
    condition     = length(module.account_baseline) == 0 && length(module.cloudtrail) == 0 && length(module.findings_notification) == 0
    error_message = "Disabled capabilities must set their module count to 0."
  }
  assert {
    condition     = output.manifest.password_policy_min_length == null && output.manifest.cloudtrail_arn == null && output.manifest.cloudtrail_bucket_name == null && output.manifest.findings_topic_arn == null
    error_message = "Manifest keys for disabled capabilities must be null."
  }
  # Capabilities left on remain composed.
  assert {
    condition     = length(module.cspm) == 1 && length(module.audit_logging) == 1
    error_message = "Capabilities left enabled must remain composed."
  }
}

# --- Negative: enable_network with empty subnets is rejected (var validation) -
run "network_without_subnets_is_rejected" {
  command = plan

  variables {
    config = {
      name_prefix    = "test-lz-bad"
      enable_network = true
      subnets        = []
    }
  }

  expect_failures = [
    var.config,
  ]
}
