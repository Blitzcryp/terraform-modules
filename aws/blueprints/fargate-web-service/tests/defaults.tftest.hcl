# Native `terraform test` for the fargate-web-service blueprint. Uses a mocked
# AWS provider so no credentials or real resources are needed. Under the mock,
# computed ARNs/IDs are unknown, so we assert on known/derived values: tier
# module instance counts (tracking the enable flags), the derived url/network
# resolution, and manifest nullness. Plan success is asserted by the run itself.

mock_provider "aws" {}

# Under the mock provider, computed data-source attributes (VPC CIDR, account id,
# region) are random strings that fail provider-side ARN/CIDR validation inside
# the composed components. Pin valid values so plans of the composed atoms hold.
override_data {
  target = module.alb.data.aws_vpc.this
  values = { cidr_block = "10.0.0.0/16" }
}

override_data {
  target = module.alb.data.aws_caller_identity.current
  values = { account_id = "111122223333" }
}

override_data {
  target = module.ecr[0].module.inspector[0].data.aws_caller_identity.current
  values = { account_id = "111122223333" }
}

override_data {
  target = module.waf[0].data.aws_caller_identity.current
  values = { account_id = "111122223333" }
}

override_data {
  target = module.waf[0].data.aws_region.current
  values = { name = "eu-central-1" }
}

variables {
  # BYO-network minimal base: app only, no domain/db/cache.
  base = {
    name_prefix     = "test-web"
    container_image = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/test-web:latest"

    vpc_id             = "vpc-00000000000000000"
    public_subnet_ids  = ["subnet-00000000000000001", "subnet-00000000000000002"]
    private_subnet_ids = ["subnet-00000000000000003", "subnet-00000000000000004"]

    # BYO cert (no domain). The ALB always terminates TLS.
    certificate_arn = "arn:aws:acm:eu-central-1:111122223333:certificate/abcd1234-ab12-cd34-ef56-abcdef123456"
  }
}

# --- Minimal config: defaults compose the always-on + default-on tiers --------
run "minimal_defaults" {
  command = plan

  variables {
    config = var.base
  }

  # No custom network -> secure-network not composed; vpc resolves to the BYO id.
  assert {
    condition     = length(module.network) == 0
    error_message = "secure-network must not be composed when create_network = false."
  }
  assert {
    condition     = local.vpc_id == "vpc-00000000000000000"
    error_message = "vpc_id must resolve to the caller-supplied id when create_network = false."
  }

  # No domain -> no ACM cert module and no DNS record; the BYO cert is used and
  # url falls back to the ALB DNS name (http:// form is domain-driven).
  assert {
    condition     = length(module.certificate) == 0 && length(module.dns_record) == 0
    error_message = "ACM cert and DNS record must not be composed without a domain_name."
  }
  assert {
    condition     = local.certificate_arn == var.base.certificate_arn
    error_message = "Without a domain_name the effective certificate must be the BYO certificate_arn."
  }

  # Default-on tiers: ECR, WAF, secrets are composed once.
  assert {
    condition     = length(module.ecr) == 1 && length(module.waf) == 1 && length(module.secrets) == 1
    error_message = "ECR, WAF and secrets tiers must be on by default (composed once)."
  }

  # Default-off tiers: database (both flavours) and cache are not composed.
  assert {
    condition     = length(module.database) == 0 && length(module.database_serverless) == 0 && length(module.cache) == 0
    error_message = "Database and cache tiers must be off by default."
  }
}

# --- All tiers enabled, created network, custom domain ------------------------
run "all_tiers_enabled" {
  command = plan

  variables {
    config = {
      name_prefix     = "test-full"
      container_image = "111122223333.dkr.ecr.eu-central-1.amazonaws.com/test-full:latest"

      create_network = true
      vpc_cidr       = "10.30.0.0/16"
      subnets = [
        { name = "public-a", cidr_block = "10.30.0.0/24", availability_zone = "eu-central-1a", public = true },
        { name = "public-b", cidr_block = "10.30.1.0/24", availability_zone = "eu-central-1b", public = true },
        { name = "private-a", cidr_block = "10.30.10.0/24", availability_zone = "eu-central-1a" },
        { name = "private-b", cidr_block = "10.30.11.0/24", availability_zone = "eu-central-1b" },
      ]

      domain_name    = "app.example.com"
      hosted_zone_id = "Z0123456789ABCDEFGHIJ"

      enable_database = true
      database        = { serverless = false }
      enable_cache    = true
    }
  }

  # Network composed once.
  assert {
    condition     = length(module.network) == 1
    error_message = "secure-network must be composed when create_network = true."
  }

  # Domain tiers composed.
  assert {
    condition     = length(module.certificate) == 1 && length(module.dns_record) == 1
    error_message = "ACM cert and DNS record must be composed when a domain_name is set."
  }

  # Provisioned Aurora chosen (serverless=false), serverless flavour absent.
  assert {
    condition     = length(module.database) == 1 && length(module.database_serverless) == 0
    error_message = "Provisioned Aurora must be composed when database.serverless = false."
  }

  # Cache composed.
  assert {
    condition     = length(module.cache) == 1
    error_message = "Cache tier must be composed when enable_cache = true."
  }

  # url uses the https://<domain> form when a domain is set.
  assert {
    condition     = local.url == "https://app.example.com"
    error_message = "url must be https://<domain> when a domain_name is set."
  }
}

# --- Serverless database flavour selection ------------------------------------
run "serverless_database_selected" {
  command = plan

  variables {
    config = merge(var.base, {
      enable_database = true
      database        = { serverless = true }
    })
  }

  assert {
    condition     = length(module.database_serverless) == 1 && length(module.database) == 0
    error_message = "Serverless Aurora must be composed when database.serverless = true."
  }
}

# --- Tiers can be disabled ----------------------------------------------------
run "tiers_disabled" {
  command = plan

  variables {
    config = merge(var.base, {
      enable_ecr     = false
      enable_waf     = false
      enable_secrets = false
    })
  }

  assert {
    condition     = length(module.ecr) == 0 && length(module.waf) == 0 && length(module.secrets) == 0
    error_message = "ECR, WAF and secrets tiers must not be composed when disabled."
  }
  assert {
    condition     = output.manifest.ecr_repository_url == null && output.manifest.waf_web_acl_arn == null && output.manifest.app_secret_arns == null
    error_message = "Manifest tier outputs must be null when their tiers are disabled."
  }
}

# --- Negative: a domain without a hosted zone is rejected (var validation) ----
run "domain_without_hosted_zone_is_rejected" {
  command = plan

  variables {
    config = merge(var.base, {
      domain_name = "app.example.com"
      # hosted_zone_id intentionally omitted
    })
  }

  expect_failures = [
    var.config,
  ]
}
