locals {
  module_tags = {
    Module = "components/dns-record"
  }
  tags = merge(local.module_tags, var.config.tags)

  # Key each record by "<name>|<type>" so the for_each map is stable and known at
  # plan time (a name+type pair uniquely identifies a record within a zone).
  records_by_key = {
    for r in var.config.records : "${r.name}|${r.type}" => r
  }
}

# One route53-record atom per requested record. Each may be a standard record
# (values) or an alias record (alias block); the atom enforces exactly-one-of.
module "record" {
  source   = "../../atoms/route53/route53-record"
  for_each = local.records_by_key

  config = {
    zone_id         = var.config.zone_id
    name            = each.value.name
    type            = each.value.type
    ttl             = each.value.ttl
    records         = each.value.values
    alias           = each.value.alias
    allow_overwrite = false
    tags            = var.config.tags
  }
}
