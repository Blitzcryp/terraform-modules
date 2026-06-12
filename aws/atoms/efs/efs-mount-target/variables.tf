variable "config" {
  description = <<-EOT
    Configuration for the EFS mount target atom. A mount target is the in-VPC
    NFS endpoint for an EFS file system in one subnet/AZ. `file_system_id` and
    `subnet_id` are required. Network exposure is governed by the supplied
    security groups (PCI DSS Req 1) — keep them to NFS-only sources.
  EOT

  type = object({
    file_system_id  = string                       # required
    subnet_id       = string                       # required
    security_groups = optional(list(string), [])   # NFS-only sources (Req 1)
    ip_address      = optional(string)             # null = AWS assigns one
  })
  # no `default` — file_system_id and subnet_id are required

  validation {
    condition     = var.config.ip_address == null || can(cidrhost("${var.config.ip_address}/32", 0))
    error_message = "config.ip_address must be a valid IPv4 address (or null to let AWS assign one)."
  }
}
