output "manifest" {
  description = "All outputs of the OpenSearch domain atom, collected on a single object."
  value = {
    arn                = aws_opensearch_domain.this.arn
    domain_id          = aws_opensearch_domain.this.domain_id
    domain_name        = aws_opensearch_domain.this.domain_name
    endpoint           = try(aws_opensearch_domain.this.endpoint, null)
    dashboard_endpoint = try(aws_opensearch_domain.this.dashboard_endpoint, null)
  }
}
