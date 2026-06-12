data "aws_vpc" "this" {
  id = var.config.vpc_id
}

locals {
  module_tags = {
    Module = "components/alb" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # ---------------------------------------------------------------------------
  # Security group ingress
  # ---------------------------------------------------------------------------
  # Default to VPC-only ingress (the VPC's CIDR), looked up from vpc_id. Callers
  # may override with explicit CIDRs; using public CIDRs additionally requires
  # the allow_public_ingress escape hatch (enforced by the security-group atom).
  ingress_cidrs = coalesce(var.config.ingress_cidrs, [data.aws_vpc.this.cidr_block])

  # The ports the ALB listens on (drives the SG openings). Derived from the
  # effective listener set so the SG only opens what the ALB actually serves.
  listener_ports = [for l in local.effective_listeners : l.port]

  ingress_rules = [
    for pair in setproduct(local.ingress_cidrs, local.listener_ports) : {
      description = "ALB ingress on port ${pair[1]} from ${pair[0]}"
      ip_protocol = "tcp"
      from_port   = pair[1]
      to_port     = pair[1]
      cidr_ipv4   = pair[0]
    }
  ]

  # ALB must reach its targets; allow all egress within the VPC CIDR by default.
  egress_rules = [
    {
      description = "ALB egress to targets within the VPC"
      ip_protocol = "-1"
      cidr_ipv4   = data.aws_vpc.this.cidr_block
    }
  ]

  # ---------------------------------------------------------------------------
  # Target groups: default to a single HTTPS:443 group when none supplied.
  # ---------------------------------------------------------------------------
  default_target_groups = [
    {
      name         = "${var.config.name}-tg"
      port         = 443
      protocol     = "HTTPS"
      health_check = {}
    }
  ]
  effective_target_groups = var.config.target_groups == null ? local.default_target_groups : var.config.target_groups

  # ---------------------------------------------------------------------------
  # Listeners: default to the canonical secure pair when none supplied.
  #   - HTTPS:443 forward to the first target group
  #   - HTTP:80 redirect to HTTPS:443
  # ---------------------------------------------------------------------------
  # Typed null redirect so both default entries unify to one list element type.
  redirect_to_https = {
    port        = "443"
    protocol    = "HTTPS"
    status_code = "HTTP_301"
  }
  default_listeners = [
    {
      port                = 443
      protocol            = "HTTPS"
      certificate_arn     = null
      ssl_policy          = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      allow_insecure_http = false
      default_action = {
        type             = "forward"
        target_group_key = 0
        # Carry a shaped (but unused) redirect so the tuple unifies to a list;
        # the lb-listener atom ignores redirect when type = "forward".
        redirect = local.redirect_to_https
      }
    },
    {
      port                = 80
      protocol            = "HTTP"
      certificate_arn     = null
      ssl_policy          = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      allow_insecure_http = false
      default_action = {
        type             = "redirect"
        target_group_key = 0
        redirect         = local.redirect_to_https
      }
    },
  ]
  # Normalise both sources to a single object shape so the conditional unifies.
  effective_listeners = [
    for l in(var.config.listeners == null ? local.default_listeners : var.config.listeners) : {
      port     = l.port
      protocol = l.protocol
      # HTTPS listeners fall back to the component-wide certificate; HTTP carries none.
      certificate_arn     = l.protocol == "HTTPS" ? coalesce(l.certificate_arn, var.config.certificate_arn) : null
      ssl_policy          = l.ssl_policy
      allow_insecure_http = l.allow_insecure_http
      default_action = {
        type             = l.default_action.type
        target_group_key = l.default_action.target_group_key == null ? 0 : l.default_action.target_group_key
        redirect         = l.default_action.redirect == null ? local.redirect_to_https : l.default_action.redirect
      }
    }
  ]

  # ---------------------------------------------------------------------------
  # Access-log bucket
  # ---------------------------------------------------------------------------
  # The component owns a dedicated access-log bucket when logging is enabled and
  # the caller did not bring their own bucket name.
  create_log_bucket = var.config.enable_access_logs && var.config.access_logs_bucket == null
  log_bucket_name   = "${var.config.name}-alb-access-logs"
  effective_log_bucket = (
    var.config.enable_access_logs
    ? coalesce(var.config.access_logs_bucket, local.create_log_bucket ? local.log_bucket_name : null)
    : null
  )

  # At least one HTTPS listener OR an HTTP listener that redirects to HTTPS must
  # exist, so the edge always offers encrypted transport (PCI DSS Req 4). This is
  # a component-wide invariant the per-listener atoms cannot see individually.
  has_secure_listener = anytrue([
    for l in local.effective_listeners :
    l.protocol == "HTTPS" || (l.default_action.type == "redirect" && try(l.default_action.redirect.protocol, "") == "HTTPS")
  ])
}

data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Component-level transport-security guard (trivial glue, no AWS resource). The
# effective listener set must terminate or redirect to TLS somewhere; otherwise
# the edge would serve only plain HTTP (PCI DSS Req 4). Surfaced as a checkable
# resource so violations fail the plan at the component boundary.
# -----------------------------------------------------------------------------
resource "terraform_data" "tls_guard" {
  input = local.has_secure_listener

  lifecycle {
    precondition {
      condition     = local.has_secure_listener
      error_message = "No HTTPS (or HTTP->HTTPS redirect) listener in config.listeners: the ALB would serve only plain HTTP. Add a TLS listener (PCI DSS Req 4)."
    }
  }
}

# -----------------------------------------------------------------------------
# Dedicated security group for the ALB.
# -----------------------------------------------------------------------------
module "security_group" {
  source = "../../atoms/vpc/security-group"

  config = {
    name        = "${var.config.name}-alb-sg"
    vpc_id      = var.config.vpc_id
    description = "Security group for ALB ${var.config.name} (managed by components/alb)"

    ingress_rules = local.ingress_rules
    egress_rules  = local.egress_rules

    # Public ingress (0.0.0.0/0) must be intentional; passed straight through.
    allow_public_ingress = var.config.allow_public_ingress

    tags = var.config.tags
  }
}

# -----------------------------------------------------------------------------
# Access-log bucket (created only when logging is on and no BYO bucket given).
# -----------------------------------------------------------------------------
# APPLY-TIME NOTE: ALB access logs only support SSE-S3 (not SSE-KMS). The
# s3-bucket atom always applies SSE-KMS, so this bucket is created with the
# atom's secure KMS default and the ELB log-delivery policy below; if the
# delivery service rejects SSE-KMS in your account/region, supply a BYO
# SSE-S3 bucket via config.access_logs_bucket. The bucket policy grants the
# modern ELB log-delivery service principal s3:PutObject under the
# AWSLogs/<account-id>/ prefix (least privilege, this account only).
module "access_logs_bucket" {
  source = "../../atoms/s3/s3-bucket"
  count  = local.create_log_bucket ? 1 : 0

  config = {
    bucket = local.log_bucket_name

    additional_policy_statements = [
      {
        Sid       = "AllowELBLogDelivery"
        Effect    = "Allow"
        Principal = { Service = "logdelivery.elasticloadbalancing.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource = (
          var.config.access_logs_prefix == null
          ? "arn:aws:s3:::${local.log_bucket_name}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
          : "arn:aws:s3:::${local.log_bucket_name}/${var.config.access_logs_prefix}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        )
      },
    ]

    tags = var.config.tags
  }
}

# -----------------------------------------------------------------------------
# The Application Load Balancer.
# -----------------------------------------------------------------------------
module "alb" {
  source = "../../atoms/alb/alb"

  config = {
    name            = var.config.name
    subnets         = var.config.subnet_ids
    security_groups = [module.security_group.manifest.id]

    internal              = var.config.internal
    allow_internet_facing = var.config.allow_internet_facing

    access_logs_bucket = local.effective_log_bucket
    access_logs_prefix = var.config.access_logs_prefix

    tags = var.config.tags
  }
}

# -----------------------------------------------------------------------------
# Target groups (one lb-target-group atom per effective entry).
# -----------------------------------------------------------------------------
module "target_groups" {
  source = "../../atoms/alb/lb-target-group"
  count  = length(local.effective_target_groups)

  config = {
    name         = local.effective_target_groups[count.index].name
    port         = local.effective_target_groups[count.index].port
    protocol     = local.effective_target_groups[count.index].protocol
    vpc_id       = var.config.vpc_id
    health_check = local.effective_target_groups[count.index].health_check
    tags         = var.config.tags
  }
}

# -----------------------------------------------------------------------------
# Listeners (one lb-listener atom per effective entry).
# -----------------------------------------------------------------------------
module "listeners" {
  source = "../../atoms/alb/lb-listener"
  count  = length(local.effective_listeners)

  config = {
    load_balancer_arn = module.alb.manifest.arn
    port              = local.effective_listeners[count.index].port
    protocol          = local.effective_listeners[count.index].protocol
    certificate_arn   = local.effective_listeners[count.index].certificate_arn
    ssl_policy        = local.effective_listeners[count.index].ssl_policy

    default_action = {
      type = local.effective_listeners[count.index].default_action.type
      target_group_arn = (
        local.effective_listeners[count.index].default_action.type == "forward"
        ? module.target_groups[local.effective_listeners[count.index].default_action.target_group_key].manifest.arn
        : null
      )
      redirect = local.effective_listeners[count.index].default_action.redirect
    }

    allow_insecure_http = local.effective_listeners[count.index].allow_insecure_http

    tags = var.config.tags
  }
}
