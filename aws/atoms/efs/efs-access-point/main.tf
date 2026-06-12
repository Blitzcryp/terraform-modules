locals {
  module_tags = {
    Module = "atoms/efs/efs-access-point" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)
}

resource "aws_efs_access_point" "this" {
  file_system_id = var.config.file_system_id

  dynamic "posix_user" {
    for_each = var.config.posix_user == null ? [] : [var.config.posix_user]
    content {
      uid            = posix_user.value.uid
      gid            = posix_user.value.gid
      secondary_gids = posix_user.value.secondary_gids
    }
  }

  dynamic "root_directory" {
    for_each = var.config.root_directory == null ? [] : [var.config.root_directory]
    content {
      path = root_directory.value.path

      dynamic "creation_info" {
        for_each = root_directory.value.creation_info == null ? [] : [root_directory.value.creation_info]
        content {
          owner_uid   = creation_info.value.owner_uid
          owner_gid   = creation_info.value.owner_gid
          permissions = creation_info.value.permissions
        }
      }
    }
  }

  tags = local.tags
}
