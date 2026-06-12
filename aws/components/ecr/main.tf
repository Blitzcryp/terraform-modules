locals {
  # Whether this component owns the CMK. A BYO key ARN skips the kms-key atom.
  create_kms = var.config.kms_key_arn == null

  # Effective CMK ARN handed to the ecr-repository atom: created or BYO.
  effective_kms_arn = local.create_kms ? module.kms_key[0].manifest.arn : var.config.kms_key_arn
}

# --- KMS CMK for image encryption at rest (created only when no BYO key) -------
# The atom's default key policy (account-root admin) is sufficient: ECR creates
# grants on the key on behalf of the account when pushing/pulling images.
module "kms_key" {
  source = "../../atoms/kms/kms-key"
  count  = local.create_kms ? 1 : 0

  config = {
    description = "ECR image-encryption CMK for ${var.config.name} (PCI DSS Req 3)"
    alias       = "ecr/${var.config.name}"
    tags        = var.config.tags
  }
}

# --- The image registry: scan-on-push, immutable tags, CMK-encrypted, lifecycle
module "repository" {
  source = "../../atoms/ecr/ecr-repository"

  config = {
    name                         = var.config.name
    kms_key_arn                  = local.effective_kms_arn
    untagged_expiry_days         = var.config.untagged_expiry_days
    additional_repository_policy = var.config.additional_repository_policy
    tags                         = var.config.tags
    # scan_on_push, image_tag_mutability (IMMUTABLE) inherited as secure defaults.
  }
}

# --- Account-level Amazon Inspector ECR scanning (created when enabled) --------
# Inspector v2 enrolment is account-wide; here we enable only ECR scanning so the
# images pushed to the repository above are continuously scanned (PCI Req 6/11).
module "inspector" {
  source = "../../atoms/inspector/inspector2-enabler"
  count  = var.config.enable_inspector ? 1 : 0

  config = {
    resource_types = ["ECR"]
  }
}
