locals {
  module_tags = {
    Module = "components/acm"
  }
  tags = merge(local.module_tags, var.config.tags)
}

# --- 1. Request the certificate (DNS-validated). ---
module "certificate" {
  source = "../../atoms/acm/acm-certificate"

  config = {
    domain_name               = var.config.domain_name
    subject_alternative_names = var.config.subject_alternative_names
    validation_method         = "DNS"
    tags                      = var.config.tags
  }
}

# --- 2. Publish one DNS validation record per domain/SAN in the supplied zone. ---
# ACM emits one entry in domain_validation_options per DISTINCT domain across the
# primary domain_name + SANs. We drive the for_each from the STATICALLY-known set
# of domains (config.domain_name + SANs, de-duplicated) so the map keys are known
# at plan time, and look the apply-time record name/type/value up from the cert
# atom's domain_validation_options (keyed by domain_name). This avoids the
# "for_each keys known only after apply" error and works under mock_provider.
locals {
  # Distinct domains the cert covers — keys are known at plan time.
  cert_domains = toset(concat([var.config.domain_name], var.config.subject_alternative_names))

  # domain_name -> validation record fields. Values are unknown until apply, but
  # the keys above are static, so for_each can enumerate the instances.
  dvo_by_domain = {
    for dvo in module.certificate.manifest.domain_validation_options :
    dvo.domain_name => dvo
  }
}

module "validation_record" {
  source   = "../../atoms/route53/route53-record"
  for_each = local.cert_domains

  config = {
    zone_id = var.config.hosted_zone_id
    name    = local.dvo_by_domain[each.key].resource_record_name
    type    = local.dvo_by_domain[each.key].resource_record_type
    records = [local.dvo_by_domain[each.key].resource_record_value]
    ttl     = 60

    # ACM re-issues/rotates may reuse the same validation record name; overwriting
    # is expected and safe for these ACM-owned CNAME validation records.
    allow_overwrite = true

    tags = var.config.tags
  }
}

# --- 3. Wait until ACM reports the certificate ISSUED, gated on those records. ---
module "validation" {
  source = "../../atoms/acm/acm-certificate-validation"

  config = {
    certificate_arn         = module.certificate.manifest.arn
    validation_record_fqdns = [for r in module.validation_record : r.manifest.fqdn]
  }
}
