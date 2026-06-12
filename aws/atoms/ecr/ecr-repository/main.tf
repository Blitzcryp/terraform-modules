locals {
  module_tags = {
    Module = "atoms/ecr/ecr-repository" # only hardcoded tag; global tags come from provider default_tags
  }
  tags = merge(local.module_tags, var.config.tags)

  # KMS when a key ARN is supplied, else AWS-managed AES256 (still encrypted).
  encryption_type = var.config.kms_key_arn == null ? "AES256" : "KMS"

  # Lifecycle policy: expire untagged images, then cap the number of tagged.
  lifecycle_policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images after ${var.config.untagged_expiry_days} days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = var.config.untagged_expiry_days
        }
        action = { type = "expire" }
      },
      {
        rulePriority = 2
        description  = "Keep only the last ${var.config.tagged_image_count} tagged images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "release", "prod", "latest"]
          countType     = "imageCountMoreThan"
          countNumber   = var.config.tagged_image_count
        }
        action = { type = "expire" }
      }
    ]
  })
}

resource "aws_ecr_repository" "this" {
  # checkov:skip=CKV_AWS_163: scan_on_push defaults to true (config.scan_on_push) and is enforced by a lifecycle precondition; weakening requires config.allow_scan_on_push_disabled. Static scanner cannot see through the optional() default.
  # checkov:skip=CKV_AWS_51: image_tag_mutability defaults to IMMUTABLE (config.image_tag_mutability) and is enforced by a lifecycle precondition; weakening requires config.allow_mutable_tags. Static scanner cannot see through the optional() default.
  name                 = var.config.name
  image_tag_mutability = var.config.image_tag_mutability
  force_delete         = var.config.force_delete

  image_scanning_configuration {
    scan_on_push = var.config.scan_on_push
  }

  encryption_configuration {
    encryption_type = local.encryption_type
    kms_key         = var.config.kms_key_arn
  }

  tags = local.tags

  lifecycle {
    # PCI DSS Req 6: vulnerability scanning on push must be intentional to weaken.
    precondition {
      condition     = var.config.scan_on_push || var.config.allow_scan_on_push_disabled
      error_message = "scan_on_push disabled without config.allow_scan_on_push_disabled=true. File a PCI exception (security@emag.ro) and set the flag."
    }
    # Image integrity: mutable tags must be intentional.
    precondition {
      condition     = var.config.image_tag_mutability == "IMMUTABLE" || var.config.allow_mutable_tags
      error_message = "image_tag_mutability=MUTABLE without config.allow_mutable_tags=true. File a PCI exception (security@emag.ro) and set the flag."
    }
  }
}

# Tightly-coupled sub-resource: lifecycle policy (hygiene + cost + reduced attack surface).
resource "aws_ecr_lifecycle_policy" "this" {
  repository = aws_ecr_repository.this.name
  policy     = local.lifecycle_policy
}

# Optional resource-based access policy.
resource "aws_ecr_repository_policy" "this" {
  count      = var.config.additional_repository_policy == null ? 0 : 1
  repository = aws_ecr_repository.this.name
  policy     = var.config.additional_repository_policy
}
