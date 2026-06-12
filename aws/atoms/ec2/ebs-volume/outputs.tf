output "manifest" {
  description = "All outputs of the EBS volume atom, collected on a single object."
  value = {
    id  = aws_ebs_volume.this.id
    arn = aws_ebs_volume.this.arn
  }
}
