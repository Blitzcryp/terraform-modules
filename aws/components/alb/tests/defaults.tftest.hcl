# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the component's secure-by-default composition.
# NOTE: under mock_provider, computed values such as ARNs and the VPC CIDR are
# unknown, so we assert on known/derived values (counts, names, ports, manifest
# nullness) and on plan success rather than on computed ARNs.

mock_provider "aws" {}

# The VPC CIDR is read via a data source; under the mock provider its computed
# attributes are random, so we pin a valid CIDR for SG ingress/egress rules.
override_data {
  target = data.aws_vpc.this
  values = {
    cidr_block = "10.0.0.0/16"
  }
}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = {
      name            = "test-alb"
      vpc_id          = "vpc-0123456789abcdef0"
      subnet_ids      = ["subnet-0aaa1111bbbb2222c", "subnet-0ddd3333eeee4444f"]
      certificate_arn = "arn:aws:acm:eu-central-1:111122223333:certificate/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  # One dedicated SG, one default target group, the canonical two-listener pair.
  assert {
    condition     = length(module.target_groups) == 1
    error_message = "A single default HTTPS target group must be created when none is supplied."
  }

  assert {
    condition     = length(module.listeners) == 2
    error_message = "The default listener set must be the HTTPS:443 + HTTP:80-redirect pair."
  }

  # A dedicated access-log bucket is created by default (logging on, no BYO bucket).
  assert {
    condition     = length(module.access_logs_bucket) == 1
    error_message = "An access-log bucket must be created by default (PCI DSS Req 10)."
  }

  # The access-log bucket name is derived from config.name (known at plan time).
  assert {
    condition     = module.access_logs_bucket[0].manifest.bucket == "test-alb-alb-access-logs"
    error_message = "Access-log bucket name must be derived from config.name."
  }

  # Effective bucket name is wired into the manifest.
  assert {
    condition     = output.manifest.access_logs_bucket == "test-alb-alb-access-logs"
    error_message = "Manifest must report the access-log bucket name."
  }

  # Default target group name is derived from config.name (known at plan time).
  assert {
    condition     = module.target_groups[0].manifest.name == "test-alb-tg"
    error_message = "Default target group name must be derived from config.name."
  }

  # The derived listener set serves ports 443 and 80 (the canonical pair). This
  # is the component's known, derived local that drives both listeners and SG.
  assert {
    condition     = local.listener_ports[0] == 443 && local.listener_ports[1] == 80
    error_message = "The default listener set must serve HTTPS:443 and HTTP:80."
  }

  # The HTTP:80 listener's action redirects to HTTPS (not a plain-HTTP forward).
  assert {
    condition     = local.effective_listeners[1].default_action.type == "redirect"
    error_message = "The :80 listener must redirect to HTTPS (PCI DSS Req 4)."
  }
}

run "byo_bucket_skips_bucket_creation" {
  command = plan

  variables {
    config = {
      name               = "test-alb-byo"
      vpc_id             = "vpc-0123456789abcdef0"
      subnet_ids         = ["subnet-0aaa1111bbbb2222c", "subnet-0ddd3333eeee4444f"]
      certificate_arn    = "arn:aws:acm:eu-central-1:111122223333:certificate/abcd1234-ab12-cd34-ef56-abcdef123456"
      access_logs_bucket = "my-existing-log-bucket"
    }
  }

  assert {
    condition     = length(module.access_logs_bucket) == 0
    error_message = "No access-log bucket must be created when a BYO bucket name is supplied."
  }

  assert {
    condition     = output.manifest.access_logs_bucket == "my-existing-log-bucket"
    error_message = "Manifest must report the BYO access-log bucket name."
  }
}

run "logging_disabled_creates_no_bucket_and_null_manifest" {
  command = plan

  variables {
    config = {
      name               = "test-alb-nolog"
      vpc_id             = "vpc-0123456789abcdef0"
      subnet_ids         = ["subnet-0aaa1111bbbb2222c", "subnet-0ddd3333eeee4444f"]
      certificate_arn    = "arn:aws:acm:eu-central-1:111122223333:certificate/abcd1234-ab12-cd34-ef56-abcdef123456"
      enable_access_logs = false
    }
  }

  assert {
    condition     = length(module.access_logs_bucket) == 0
    error_message = "No bucket when access logs are disabled."
  }

  assert {
    condition     = output.manifest.access_logs_bucket == null
    error_message = "Manifest access_logs_bucket must be null when logging is disabled."
  }
}

# Negative (validation -> var.config): fewer than two subnets is rejected.
run "single_subnet_is_rejected" {
  command = plan

  variables {
    config = {
      name            = "test-alb-badsubnets"
      vpc_id          = "vpc-0123456789abcdef0"
      subnet_ids      = ["subnet-0aaa1111bbbb2222c"]
      certificate_arn = "arn:aws:acm:eu-central-1:111122223333:certificate/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  expect_failures = [
    var.config,
  ]
}

# Negative (precondition -> resource): a custom listener set that offers no TLS
# (a single plain-HTTP forward, allowed at the atom level via allow_insecure_http)
# is blocked by the component's transport-security precondition (PCI DSS Req 4).
run "no_tls_listener_is_blocked_by_precondition" {
  command = plan

  variables {
    config = {
      name       = "test-alb-notls"
      vpc_id     = "vpc-0123456789abcdef0"
      subnet_ids = ["subnet-0aaa1111bbbb2222c", "subnet-0ddd3333eeee4444f"]
      target_groups = [
        { name = "test-alb-notls-tg", port = 80, protocol = "HTTP" }
      ]
      listeners = [
        {
          port                = 80
          protocol            = "HTTP"
          allow_insecure_http = true
          default_action = {
            type             = "forward"
            target_group_key = 0
          }
        }
      ]
    }
  }

  expect_failures = [
    terraform_data.tls_guard,
  ]
}
