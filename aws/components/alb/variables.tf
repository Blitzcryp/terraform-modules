variable "config" {
  description = <<-EOT
    Configuration for the alb component: an Application Load Balancer with its own
    dedicated security group, one or more listeners, one or more target groups, and
    (when logging is enabled and no BYO bucket is supplied) a dedicated, locked-down
    S3 access-log bucket. All inputs live on this single object.

    PCI-DSS-compliant defaults are baked into the optional() fields, so supplying
    only the required fields yields a compliant, INTERNAL load balancer that:
      - terminates TLS with a TLS1.2+ policy on :443 (when certificate_arn is set),
      - redirects :80 -> :443,
      - restricts SG ingress to the VPC CIDR,
      - ships access logs to S3 (PCI DSS Req 10).
    Insecure choices require flipping an explicit `allow_*` escape hatch.
  EOT

  type = object({
    name       = string       # required — base name for the ALB and its child resources
    vpc_id     = string       # required — VPC the ALB and SG live in
    subnet_ids = list(string) # required — at least two subnets across AZs

    # --- Exposure (PCI DSS Req 1: limit inbound/outbound) ---
    internal = optional(bool, true) # not internet-facing by default
    # ESCAPE HATCH: passthrough to the alb atom; permits internal=false.
    allow_internet_facing = optional(bool, false)

    # --- TLS (PCI DSS Req 4: encrypt transmission) ---
    # ARN of an ACM certificate for the HTTPS listener. Required for the default
    # HTTPS:443 listener; may be omitted only if the caller supplies a custom
    # `listeners` list that contains no HTTPS listener.
    certificate_arn = optional(string)

    # --- Listeners --------------------------------------------------------
    # When null (default), the component creates the canonical secure pair:
    #   - HTTPS:443 -> forward to the first target group
    #   - HTTP:80   -> redirect to HTTPS:443
    # Override to author your own set. Each entry maps to one lb-listener atom.
    listeners = optional(list(object({
      port            = number
      protocol        = optional(string, "HTTPS")
      certificate_arn = optional(string) # falls back to config.certificate_arn
      ssl_policy      = optional(string, "ELBSecurityPolicy-TLS13-1-2-2021-06")
      default_action = optional(object({
        type             = optional(string, "forward")
        target_group_key = optional(number) # index into target_groups for forward
        redirect = optional(object({
          port        = optional(string, "443")
          protocol    = optional(string, "HTTPS")
          status_code = optional(string, "HTTP_301")
        }))
      }), {})
      allow_insecure_http = optional(bool, false)
    })))

    # --- Target groups ----------------------------------------------------
    # When null (default), the component creates a single HTTPS:443 target group.
    target_groups = optional(list(object({
      name     = string
      port     = number
      protocol = optional(string, "HTTPS")
      health_check = optional(object({
        path                = optional(string, "/")
        port                = optional(string, "traffic-port")
        protocol            = optional(string, "HTTPS")
        matcher             = optional(string, "200")
        interval            = optional(number, 30)
        timeout             = optional(number, 5)
        healthy_threshold   = optional(number, 3)
        unhealthy_threshold = optional(number, 3)
      }), {})
    })))

    # --- Security group ingress ------------------------------------------
    # CIDRs allowed to reach the ALB. When null (default) ingress is restricted
    # to the VPC CIDR (looked up from vpc_id). Setting public CIDRs (0.0.0.0/0)
    # also requires allow_public_ingress=true (passed to the SG atom).
    ingress_cidrs = optional(list(string))
    # ESCAPE HATCH: passthrough to the security-group atom; permits public ingress.
    allow_public_ingress = optional(bool, false)

    # --- Access logging (PCI DSS Req 10) ---------------------------------
    enable_access_logs = optional(bool, true)
    # BYO access-log bucket NAME. When set, the component does NOT create a bucket
    # and assumes the caller has attached the required ELB log-delivery policy.
    access_logs_bucket = optional(string)
    access_logs_prefix = optional(string)

    tags = optional(map(string), {})
  })

  # no `default` here because name/vpc_id/subnet_ids are required

  validation {
    condition     = length(var.config.subnet_ids) >= 2
    error_message = "config.subnet_ids must list at least two subnets across AZs for availability."
  }

  validation {
    condition     = var.config.certificate_arn == null || can(regex("^arn:aws[a-zA-Z-]*:acm:", var.config.certificate_arn))
    error_message = "config.certificate_arn, when set, must be a valid ACM certificate ARN (arn:aws:acm:...)."
  }

  # If using the default listener set (listeners == null), a certificate is
  # mandatory because the default set includes an HTTPS:443 listener (PCI Req 4).
  validation {
    condition     = var.config.listeners != null || var.config.certificate_arn != null
    error_message = "config.certificate_arn is required when using the default listener set (HTTPS:443). Supply a certificate or provide a custom config.listeners list."
  }
}
