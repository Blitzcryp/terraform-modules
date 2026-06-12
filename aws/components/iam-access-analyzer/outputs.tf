output "manifest" {
  description = "All outputs of the IAM Access Analyzer component, collected on a single object."
  value = {
    analyzer_arn  = module.analyzer.manifest.arn
    analyzer_name = module.analyzer.manifest.analyzer_name
  }
}
