variable "config" {
  description = <<-EOT
    Configuration for the EFS access point atom. An access point enforces a
    POSIX identity and a root directory for application access to an EFS file
    system (least-privilege, PCI DSS Req 7). `file_system_id` is required.
  EOT

  type = object({
    file_system_id = string # required

    posix_user = optional(object({
      uid            = number
      gid            = number
      secondary_gids = optional(list(number), [])
    }))

    root_directory = optional(object({
      path = string
      creation_info = optional(object({
        owner_uid   = number
        owner_gid   = number
        permissions = string
      }))
    }))

    tags = optional(map(string), {})
  })
  # no `default` — file_system_id is required

  validation {
    condition     = var.config.root_directory == null || var.config.root_directory.creation_info == null || can(regex("^[0-7]{3,4}$", var.config.root_directory.creation_info.permissions))
    error_message = "config.root_directory.creation_info.permissions must be octal Unix permission bits (e.g. 0755 or 755)."
  }
}
