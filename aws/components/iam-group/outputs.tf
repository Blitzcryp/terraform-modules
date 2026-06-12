output "manifest" {
  description = "All outputs of the iam-group component, collected on a single object."
  value = {
    group_arn  = module.group.manifest.arn
    group_name = module.group.manifest.name

    # The managed-policy ARNs attached to the group (the keys of the for_each).
    attached_policy_arns = [for m in module.policy_attachment : m.manifest.policy_arn]

    # The group's members; empty list when no membership is managed.
    members = local.manage_membership ? module.membership[0].manifest.users : []
  }
}
