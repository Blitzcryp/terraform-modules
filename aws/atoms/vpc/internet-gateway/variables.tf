variable "config" {
  description = <<-EOT
    Configuration for the internet gateway. All inputs live on this single
    object. The gateway is attached to the given VPC. Required field (vpc_id)
    has no default, so config cannot be omitted.
  EOT

  type = object({
    vpc_id = string           # required — no default
    name   = optional(string) # null = no Name tag override
    tags   = optional(map(string), {})
  })

  # no `default` here because vpc_id is required
}
