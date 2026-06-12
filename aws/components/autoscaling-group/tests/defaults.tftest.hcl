# Native `terraform test`. Uses a mocked AWS provider so no real credentials or
# resources are needed — validates the secure-by-default composition.
# Child modules expose only their `manifest` (not their `config`), and ARNs/IDs
# are unknown under a mock provider — so assertions target known/derived values:
# child-module instance counts (which prove the conditional wiring), the
# component's own derived locals, manifest nullness, and plan success.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      name       = "test-app"
      image_id   = "ami-0a1b2c3d4e5f60718"
      vpc_id     = "vpc-0a1b2c3d4e5f60718"
      subnet_ids = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]

      allowed_security_group_ids = ["sg-0a1b2c3d4e5f60099"]
      allowed_cidrs              = ["10.0.0.0/16"]
    }
  }

  # No BYO key supplied => the component self-provisions a KMS key.
  assert {
    condition     = length(module.kms) == 1
    error_message = "A dedicated KMS key must be created when no BYO key is supplied."
  }

  # Launch template, SG, role, profile, and ASG are each composed exactly once.
  assert {
    condition     = length(module.launch_template) == 1 && length(module.autoscaling_group) == 1 && length(module.security_group) == 1 && length(module.role) == 1 && length(module.instance_profile) == 1
    error_message = "Component must compose one of each: launch-template, asg, security-group, role, instance-profile."
  }

  # No target groups => EC2 health checks (not ELB).
  assert {
    condition     = local.health_check_type == "EC2"
    error_message = "Health check type must default to EC2 when no target groups are attached."
  }

  # One ingress rule per allowed SG and one per CIDR; no public ingress generated.
  assert {
    condition     = length(local.ingress_rules) == 2
    error_message = "Instance security group must have exactly one ingress rule per allowed SG/CIDR."
  }

  # The EC2 trust policy names only the EC2 service principal.
  assert {
    condition     = jsondecode(local.assume_role_policy).Statement[0].Principal.Service == "ec2.amazonaws.com"
    error_message = "Instance role must be assumable only by the EC2 service."
  }

  # The manifest exposes the expected keys.
  assert {
    condition     = can(output.manifest.asg_arn) && can(output.manifest.asg_name) && can(output.manifest.launch_template_id) && can(output.manifest.security_group_id) && can(output.manifest.role_arn) && can(output.manifest.kms_key_arn)
    error_message = "manifest must expose all documented keys."
  }
}

run "byo_key_skips_kms_creation" {
  command = plan

  variables {
    config = {
      name        = "test-app"
      image_id    = "ami-0a1b2c3d4e5f60718"
      vpc_id      = "vpc-0a1b2c3d4e5f60718"
      subnet_ids  = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
      kms_key_arn = "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    }
  }

  # BYO key => no KMS key is created and the manifest surfaces the BYO arn.
  assert {
    condition     = length(module.kms) == 0
    error_message = "A BYO kms_key_arn must skip self-provisioning the KMS key."
  }

  assert {
    condition     = output.manifest.kms_key_arn == "arn:aws:kms:eu-central-1:111122223333:key/abcd1234-ab12-cd34-ef56-abcdef123456"
    error_message = "BYO kms_key_arn must be passed through to the manifest."
  }
}

run "target_groups_switch_to_elb_health_checks" {
  command = plan

  variables {
    config = {
      name              = "test-app"
      image_id          = "ami-0a1b2c3d4e5f60718"
      vpc_id            = "vpc-0a1b2c3d4e5f60718"
      subnet_ids        = ["subnet-0a1b2c3d4e5f60001", "subnet-0a1b2c3d4e5f60002"]
      target_group_arns = ["arn:aws:elasticloadbalancing:eu-central-1:111122223333:targetgroup/app/0123456789abcdef"]
    }
  }

  assert {
    condition     = local.health_check_type == "ELB"
    error_message = "Attaching a target group must switch health checks to ELB."
  }
}

# Negative: fewer than two subnets violates the subnet-count validation.
run "requires_two_subnets" {
  command = plan

  variables {
    config = {
      name       = "test-app"
      image_id   = "ami-0a1b2c3d4e5f60718"
      vpc_id     = "vpc-0a1b2c3d4e5f60718"
      subnet_ids = ["subnet-0a1b2c3d4e5f60001"]
    }
  }

  expect_failures = [
    var.config,
  ]
}
