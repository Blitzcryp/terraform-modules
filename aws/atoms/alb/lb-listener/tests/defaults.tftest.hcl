# Native `terraform test`. Uses a mocked AWS provider so no real credentials
# or resources are needed — validates the module's secure-by-default behaviour.

mock_provider "aws" {}

run "secure_defaults" {
  command = plan

  variables {
    config = {
      load_balancer_arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:loadbalancer/app/test/0123456789abcdef"
      port              = 443
      certificate_arn   = "arn:aws:acm:eu-central-1:123456789012:certificate/11111111-2222-3333-4444-555555555555"
      default_action = {
        type             = "forward"
        target_group_arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:targetgroup/test/abcdef0123456789"
      }
    }
  }

  assert {
    condition     = aws_lb_listener.this.protocol == "HTTPS"
    error_message = "Listener must default to HTTPS (PCI DSS Req 4)."
  }

  assert {
    condition     = aws_lb_listener.this.ssl_policy == "ELBSecurityPolicy-TLS13-1-2-2021-06"
    error_message = "Listener must default to a TLS1.2+ SSL policy."
  }
}

run "http_redirect_to_https_is_allowed_without_escape_hatch" {
  command = plan

  variables {
    config = {
      load_balancer_arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:loadbalancer/app/test/0123456789abcdef"
      port              = 80
      protocol          = "HTTP"
      default_action = {
        type = "redirect"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
      # allow_insecure_http intentionally left false — redirect makes it compliant
    }
  }

  assert {
    condition     = aws_lb_listener.this.protocol == "HTTP"
    error_message = "Redirect listener should keep protocol HTTP."
  }
}

run "insecure_http_is_blocked_without_escape_hatch" {
  command = plan

  variables {
    config = {
      load_balancer_arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:loadbalancer/app/test/0123456789abcdef"
      port              = 80
      protocol          = "HTTP"
      default_action = {
        type             = "forward"
        target_group_arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:targetgroup/test/abcdef0123456789"
      }
      # allow_insecure_http intentionally left at its false default
    }
  }

  expect_failures = [
    aws_lb_listener.this,
  ]
}

run "https_without_certificate_is_rejected" {
  command = plan

  variables {
    config = {
      load_balancer_arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:loadbalancer/app/test/0123456789abcdef"
      port              = 443
      default_action = {
        type             = "forward"
        target_group_arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:targetgroup/test/abcdef0123456789"
      }
      # protocol defaults to HTTPS but certificate_arn omitted
    }
  }

  expect_failures = [
    var.config,
  ]
}
