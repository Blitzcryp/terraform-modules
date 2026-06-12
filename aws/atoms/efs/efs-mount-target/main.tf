# An EFS mount target has no tags argument (AWS does not support tagging it),
# so this atom carries only the module-identity comment, not a tags local.

resource "aws_efs_mount_target" "this" {
  file_system_id  = var.config.file_system_id
  subnet_id       = var.config.subnet_id
  security_groups = length(var.config.security_groups) > 0 ? var.config.security_groups : null
  ip_address      = var.config.ip_address
}
