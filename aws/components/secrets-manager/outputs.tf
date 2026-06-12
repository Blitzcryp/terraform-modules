output "manifest" {
  description = "All outputs of the secrets-manager component, collected on a single object."
  value = {
    # KMS: created-or-BYO ARN that encrypts every secret.
    kms_key_arn = local.kms_key_arn
    # key_id is null when BYOK (we don't own the key).
    kms_key_id = local.create_kms_key ? module.kms_key[0].manifest.key_id : null

    # Maps keyed by the logical secret name (the map key, not the full name).
    secret_arns = { for k, m in module.secret : k => m.manifest.secret_arn }
    secret_ids  = { for k, m in module.secret : k => m.manifest.secret_id }
  }
}
