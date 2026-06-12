output "manifest" {
  description = "All outputs of the dynamodb component, collected on a single object."
  value = {
    table_arn  = module.table.manifest.arn
    table_name = module.table.manifest.name
    stream_arn = module.table.manifest.stream_arn

    # created-or-BYO ARN that encrypts the table.
    kms_key_arn = local.kms_key_arn
  }
}
