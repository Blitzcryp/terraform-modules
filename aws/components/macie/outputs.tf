output "manifest" {
  description = "All outputs of the Macie component, collected on a single object."
  value = {
    macie_account_id = module.macie_account.manifest.account_id
    service_role     = module.macie_account.manifest.service_role
  }
}
