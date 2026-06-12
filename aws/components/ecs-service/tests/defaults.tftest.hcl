# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed. Under the mock, computed ARNs/IDs are unknown, so we
# assert on known/derived values (module instance counts, derived names, the
# autoscaling resource_id parsed from the cluster ARN, manifest nullness) and on
# plan success rather than on computed ARNs.

mock_provider "aws" {}

variables {
  base = {
    name                  = "test-web"
    cluster_arn           = "arn:aws:ecs:eu-central-1:111122223333:cluster/test-app"
    vpc_id                = "vpc-00000000000000000"
    subnet_ids            = ["subnet-00000000000000001", "subnet-00000000000000002"]
    kms_key_arn           = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    container_definitions = "[{\"name\":\"web\",\"image\":\"nginx\",\"essential\":true}]"
  }
}

run "secure_defaults_compose_all_atoms" {
  command = plan

  variables {
    config = var.base
  }

  # Autoscaling is on by default -> the atom is created once.
  assert {
    condition     = length(module.autoscaling) == 1
    error_message = "Autoscaling atom must be created by default (enable_autoscaling defaults to true)."
  }

  # App log group name derived from the service name (echoed by the atom).
  assert {
    condition     = module.log_group.manifest.name == "/ecs/test-web/app"
    error_message = "App log group name must be derived from config.name."
  }

  # Service name echoed (known at plan time).
  assert {
    condition     = module.ecs_service.manifest.name == "test-web"
    error_message = "Service name must equal config.name."
  }

  # The autoscaling target resource_id is derived from the cluster name parsed
  # out of the cluster ARN plus the service name.
  assert {
    condition     = module.autoscaling[0].manifest.target_resource_id == "service/test-app/test-web"
    error_message = "Autoscaling resource_id must be service/<cluster-name>/<service-name>."
  }

  # No load balancer wiring by default.
  assert {
    condition     = length(local.load_balancers) == 0
    error_message = "No load balancer must be wired when target_group_arn is unset."
  }

  # Private networking by default (assign_public_ip false).
  assert {
    condition     = module.ecs_service.manifest.name == "test-web" && local.load_balanced == false
    error_message = "Service must default to non-load-balanced, private networking."
  }
}

run "load_balanced_wiring" {
  command = plan

  variables {
    config = merge(var.base, {
      target_group_arn = "arn:aws:elasticloadbalancing:eu-central-1:111122223333:targetgroup/test-web/0123456789abcdef"
      container_name   = "web"
      container_port   = 8443
    })
  }

  assert {
    condition     = length(local.load_balancers) == 1
    error_message = "A load balancer mapping must be wired when target_group_arn is set."
  }

  assert {
    condition     = local.load_balancers[0].container_name == "web" && local.load_balancers[0].container_port == 8443
    error_message = "Load balancer mapping must use the configured container name and port."
  }
}

run "autoscaling_disabled" {
  command = plan

  variables {
    config = merge(var.base, {
      enable_autoscaling = false
    })
  }

  assert {
    condition     = length(module.autoscaling) == 0
    error_message = "No autoscaling atom must be created when enable_autoscaling = false."
  }

  assert {
    condition     = output.manifest.autoscaling_policy_arns == null
    error_message = "autoscaling_policy_arns must be null when autoscaling is disabled."
  }
}

# Negative case (validation): load-balanced without container name/port.
run "lb_without_container_details_is_rejected" {
  command = plan

  variables {
    config = merge(var.base, {
      target_group_arn = "arn:aws:elasticloadbalancing:eu-central-1:111122223333:targetgroup/test-web/0123456789abcdef"
    })
  }

  expect_failures = [
    var.config,
  ]
}

# Negative case (precondition): public IP without the escape hatch is blocked by
# the ecs-service atom's lifecycle precondition.
run "public_ip_without_escape_hatch_is_blocked" {
  command = plan

  variables {
    config = merge(var.base, {
      assign_public_ip = true
      # allow_public_ip intentionally left at its false default
    })
  }

  expect_failures = [
    terraform_data.guards,
  ]
}
