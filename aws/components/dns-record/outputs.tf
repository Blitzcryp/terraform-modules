output "manifest" {
  description = "All outputs of the dns-record component, collected on a single object."
  value = {
    # FQDNs and ids of every created record, in stable (sorted-by-key) order.
    record_fqdns = [for k in sort(keys(module.record)) : module.record[k].manifest.fqdn]
    record_ids   = [for k in sort(keys(module.record)) : module.record[k].manifest.record_id]
  }
}
