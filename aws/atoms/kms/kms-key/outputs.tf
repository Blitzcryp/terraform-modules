output "manifest" {
  description = "All outputs of the KMS key atom, collected on a single object."
  value = {
    key_id     = aws_kms_key.this.key_id
    arn        = aws_kms_key.this.arn
    alias_arn  = try(aws_kms_alias.this[0].arn, null)
    alias_name = try(aws_kms_alias.this[0].name, null)
  }
}
