variable "config" {
  description = <<-EOT
    Configuration for the dns-record component: point one or more DNS names at
    AWS resources (or arbitrary values) within a single Route53 hosted zone. All
    inputs live on this single object.

    Each entry in `records` is either a STANDARD record (set `values`, leave
    `alias` null) or an ALIAS record (set `alias`, leave `values` empty) — the
    underlying route53-record atom enforces exactly-one-of. Alias records are how
    you point an apex/subdomain at an ALB, CloudFront distribution, or S3 website.

    This component composes the route53/route53-record atom via module blocks —
    one instance per record.

    NOTE: aws_route53_record does not support tags. `tags` is accepted for
    library uniformity but is not applied to any resource.
  EOT

  type = object({
    zone_id = string # required — the hosted zone all records are created in

    records = list(object({
      name   = string
      type   = optional(string, "A")
      ttl    = optional(number, 300)      # standard records only; ignored for alias
      values = optional(list(string), []) # standard records only
      alias = optional(object({           # alias records only
        name                   = string
        zone_id                = string
        evaluate_target_health = optional(bool, true)
      }))
    })) # required — at least one record

    tags = optional(map(string), {})
  })
  # `zone_id` and `records` are required, so no `default = {}`.

  validation {
    condition     = length(var.config.zone_id) > 0
    error_message = "config.zone_id must be a non-empty Route53 hosted zone id."
  }

  validation {
    condition     = length(var.config.records) > 0
    error_message = "config.records must contain at least one record."
  }

  # Per record: exactly one of values or alias (mirrors the atom's contract, but
  # surfaced at the component boundary so callers get a clear early failure).
  validation {
    condition = alltrue([
      for r in var.config.records : (r.alias != null) != (length(r.values) > 0)
    ])
    error_message = "Each config.records entry must set exactly one of `values` (standard record) or `alias` (alias record)."
  }

  # Record names must be unique by (name, type) so for_each keys do not collide.
  validation {
    condition     = length(var.config.records) == length(distinct([for r in var.config.records : "${r.name}|${r.type}"]))
    error_message = "Each config.records entry must have a unique (name, type) pair."
  }
}
