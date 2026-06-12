locals {
  module_tags = {
    Module = "atoms/alb/lb-listener" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  is_https = var.config.protocol == "HTTPS"

  # A plain-HTTP listener is tolerated without the escape hatch only when its
  # sole default action redirects to HTTPS (the canonical HTTP->HTTPS pattern).
  da = var.config.default_action
  is_redirect_to_https = (
    local.da.type == "redirect" &&
    local.da.redirect != null &&
    try(local.da.redirect.protocol, "") == "HTTPS"
  )

  # HTTPS uses ssl_policy + certificate_arn; HTTP must not set them.
  ssl_policy      = local.is_https ? var.config.ssl_policy : null
  certificate_arn = local.is_https ? var.config.certificate_arn : null
}

resource "aws_lb_listener" "this" {
  # checkov:skip=CKV_AWS_2: protocol is optional(string, "HTTPS") on config and
  #   checkov cannot statically resolve the value through the config object. The
  #   secure HTTPS default is enforced by the secure_defaults test, and a plain
  #   HTTP listener that does not redirect to HTTPS is blocked by the lifecycle
  #   precondition unless config.allow_insecure_http=true (PCI DSS Req 4).
  load_balancer_arn = var.config.load_balancer_arn
  port              = var.config.port
  protocol          = var.config.protocol

  ssl_policy      = local.ssl_policy
  certificate_arn = local.certificate_arn

  default_action {
    type             = var.config.default_action.type
    target_group_arn = var.config.default_action.type == "forward" ? var.config.default_action.target_group_arn : null

    dynamic "redirect" {
      for_each = var.config.default_action.type == "redirect" ? [var.config.default_action.redirect] : []
      content {
        port        = redirect.value.port
        protocol    = redirect.value.protocol
        status_code = redirect.value.status_code
      }
    }
  }

  tags = local.tags

  lifecycle {
    # Plain-HTTP traffic must be encrypted in transit (PCI DSS Req 4). An HTTP
    # listener is allowed only when it redirects to HTTPS, or when the operator
    # explicitly opts out via the escape hatch.
    precondition {
      condition     = local.is_https || local.is_redirect_to_https || var.config.allow_insecure_http
      error_message = "Plain-HTTP listener that does not redirect to HTTPS requires config.allow_insecure_http=true. File a PCI exception (security@emag.ro) and set the flag (PCI DSS Req 4)."
    }
  }
}
