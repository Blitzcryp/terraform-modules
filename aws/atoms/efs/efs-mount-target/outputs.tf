output "manifest" {
  description = "All outputs of the EFS mount target atom, collected on a single object."
  value = {
    id                     = aws_efs_mount_target.this.id
    ip_address             = aws_efs_mount_target.this.ip_address
    network_interface_id   = aws_efs_mount_target.this.network_interface_id
    availability_zone_name = aws_efs_mount_target.this.availability_zone_name
  }
}
