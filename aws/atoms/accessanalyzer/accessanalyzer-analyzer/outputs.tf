output "manifest" {
  description = "All outputs of the IAM Access Analyzer atom, collected on a single object."
  value = {
    id            = aws_accessanalyzer_analyzer.this.id
    arn           = aws_accessanalyzer_analyzer.this.arn
    analyzer_name = aws_accessanalyzer_analyzer.this.analyzer_name
  }
}
