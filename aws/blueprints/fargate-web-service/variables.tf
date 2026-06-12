variable "config" {
  description = <<-EOT
    Single configuration object for the fargate-web-service BLUEPRINT: a full,
    PCI-secure-by-default containerised web service on AWS Fargate, composed
    entirely from components. All inputs live on this one object.

    Secure-by-default: tasks run in PRIVATE subnets with no public IP, logs and
    data are encrypted at rest, WAF + ECR scanning + secrets management are on by
    default, and the only public entrypoint is the (intentionally internet-facing)
    ALB. Optional tiers (network creation, custom domain/TLS, database, cache,
    secrets, ECR) are toggled with explicit enable flags and nested config.

    SECURITY: never put secret values in `environment` (plaintext env vars). Use
    `enable_secrets` + reference the resulting secret ARNs in your task's
    container `secrets` block, or surface the DB master-user secret (PCI DSS
    Req 3 / Req 8).
  EOT

  type = object({
    # --- Always required ---
    name_prefix = string                    # base name for every composed resource
    tags        = optional(map(string), {}) # instance tags (global tags come from provider default_tags)

    # --- Application (container) ---
    container_image    = string # required — image URI (e.g. an ECR repo URI:tag)
    container_name     = optional(string, "app")
    container_port     = optional(number, 8080)
    desired_count      = optional(number, 2) # >1 for availability
    cpu                = optional(string, "512")
    memory             = optional(string, "1024")
    environment        = optional(map(string), {}) # NON-SECRET env vars only
    execution_role_arn = optional(string)          # pass-through to the task definition
    task_role_arn      = optional(string)          # pass-through to the task definition

    # --- Network: bring-your-own (default) or create a secure-network ---
    create_network = optional(bool, false)
    # BYO (create_network = false): supply existing ids.
    vpc_id             = optional(string)
    public_subnet_ids  = optional(list(string), [])
    private_subnet_ids = optional(list(string), [])
    # Create (create_network = true): a secure-network is composed.
    vpc_cidr = optional(string, "10.0.0.0/16")
    subnets = optional(list(object({
      name              = string
      cidr_block        = string
      availability_zone = string
      public            = optional(bool, false)
    })), [])

    # --- Domain / TLS. The ALB ALWAYS terminates TLS at the edge (PCI DSS Req 4;
    # the alb component has no plain-HTTP escape hatch), so a certificate is
    # mandatory. Provide it ONE of two ways:
    #   - set domain_name (+ hosted_zone_id): the blueprint composes acm to issue
    #     a DNS-validated cert and adds an alias A record pointing at the ALB, or
    #   - set certificate_arn: bring your own ACM cert (no DNS record is created).
    domain_name     = optional(string)
    hosted_zone_id  = optional(string)
    certificate_arn = optional(string) # BYO cert; used when domain_name is unset

    # --- Optional tier: ECR repository for the app image (PCI DSS Req 6) ---
    enable_ecr = optional(bool, true)

    # --- Optional tier: WAF on the ALB (PCI DSS Req 6.6) ---
    enable_waf = optional(bool, true)

    # --- Optional tier: Aurora database (private; reachable only from the app SG) ---
    enable_database = optional(bool, false)
    database = optional(object({
      engine         = optional(string, "aurora-postgresql")
      serverless     = optional(bool, false)
      instance_class = optional(string, "db.r6g.large")
      instance_count = optional(number, 2)
      min_capacity   = optional(number, 0.5) # serverless v2 ACUs
      max_capacity   = optional(number, 4)   # serverless v2 ACUs
    }), {})

    # --- Optional tier: ElastiCache Redis (private; reachable only from the app SG) ---
    enable_cache = optional(bool, false)
    cache = optional(object({
      node_type          = optional(string, "cache.t4g.medium")
      num_cache_clusters = optional(number, 2)
    }), {})

    # --- Optional tier: Secrets Manager vault for app secrets (PCI DSS Req 3/8) ---
    enable_secrets = optional(bool, true)
    secrets = optional(map(object({
      description         = optional(string)
      rotation_lambda_arn = optional(string)
      rotation_days       = optional(number, 30)
    })), {})
  })
  # no `default` here because name_prefix and container_image are required

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]{1,200}$", var.config.name_prefix))
    error_message = "config.name_prefix must be 1-200 chars of letters, numbers, or hyphens."
  }

  validation {
    condition     = length(var.config.container_image) > 0
    error_message = "config.container_image must be a non-empty image URI."
  }

  # BYO network: a vpc_id and at least two subnets of each kind are required when
  # the blueprint is not creating the network itself.
  validation {
    condition     = var.config.create_network || (var.config.vpc_id != null && length(var.config.public_subnet_ids) >= 2 && length(var.config.private_subnet_ids) >= 2)
    error_message = "When config.create_network = false you must supply config.vpc_id plus at least two public_subnet_ids and two private_subnet_ids (the ALB and tasks span AZs)."
  }

  # Create network: at least two public and two private subnet definitions.
  validation {
    condition = !var.config.create_network || (
      length([for s in var.config.subnets : s if s.public]) >= 2 &&
      length([for s in var.config.subnets : s if !s.public]) >= 2
    )
    error_message = "When config.create_network = true you must define at least two public and two private entries in config.subnets (across AZs)."
  }

  # A custom domain requires the hosted zone that ACM validates / the alias lives in.
  validation {
    condition     = var.config.domain_name == null || var.config.hosted_zone_id != null
    error_message = "config.hosted_zone_id is required when config.domain_name is set (used for ACM DNS validation and the alias record)."
  }

  # The ALB always terminates TLS, so a cert source is mandatory: either an
  # ACM-issued cert (domain_name) or a bring-your-own certificate_arn.
  validation {
    condition     = var.config.domain_name != null || var.config.certificate_arn != null
    error_message = "A TLS certificate is required: set config.domain_name (to issue one via ACM) or config.certificate_arn (bring your own). The ALB always serves HTTPS (PCI DSS Req 4)."
  }

  validation {
    condition     = var.config.certificate_arn == null || can(regex("^arn:aws[a-zA-Z-]*:acm:", var.config.certificate_arn))
    error_message = "config.certificate_arn, when set, must be a valid ACM certificate ARN (arn:aws:acm:...)."
  }
}
