output "manifest" {
  description = "All outputs of the SSM parameter atom, collected on a single object."
  sensitive   = true # the parameter resource is value-tainted; manifest fields inherit it
  value = {
    arn     = aws_ssm_parameter.this.arn
    name    = aws_ssm_parameter.this.name
    version = aws_ssm_parameter.this.version
    type    = aws_ssm_parameter.this.type
  }
}
