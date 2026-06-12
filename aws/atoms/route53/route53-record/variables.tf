variable "config" {
  description = <<-EOT
    Configuration for a single Route53 record. All inputs live on this single
    object. The record is either a STANDARD record (`records` + `ttl`) or an
    ALIAS record (`alias` block pointing at an AWS resource) — exactly one of the
    two must be supplied.

    NOTE: aws_route53_record does NOT support tags. `tags` is accepted only so
    this atom's config shape matches the rest of the library; it is not applied
    to any resource.
  EOT

  type = object({
    zone_id = string # required — hosted zone id
    name    = string # required — record name (FQDN or relative to the zone)
    type    = string # required — A | AAAA | CNAME | TXT | MX | NS | SRV | CAA

    ttl     = optional(number, 300)      # standard records only; ignored for alias
    records = optional(list(string), []) # standard records only; ignored for alias

    # Alias record target. When set, ttl/records are omitted (alias record).
    alias = optional(object({
      name                   = string
      zone_id                = string
      evaluate_target_health = optional(bool, true)
    }))

    allow_overwrite = optional(bool, false) # do not clobber existing records by default
    tags            = optional(map(string), {})
  })
  # `zone_id`, `name`, `type` are required, so no `default = {}`.

  validation {
    condition     = contains(["A", "AAAA", "CNAME", "TXT", "MX", "NS", "SRV", "CAA"], var.config.type)
    error_message = "config.type must be one of A, AAAA, CNAME, TXT, MX, NS, SRV, CAA."
  }

  # Exactly one of `records` or `alias` must be provided.
  validation {
    condition     = (var.config.alias != null) != (length(var.config.records) > 0)
    error_message = "Provide exactly one of config.records (standard record) or config.alias (alias record), not both or neither."
  }
}
