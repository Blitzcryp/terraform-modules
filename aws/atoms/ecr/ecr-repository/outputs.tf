output "manifest" {
  description = "All outputs of the ECR repository atom, collected on a single object."
  value = {
    name           = aws_ecr_repository.this.name
    arn            = aws_ecr_repository.this.arn
    repository_url = aws_ecr_repository.this.repository_url
    registry_id    = aws_ecr_repository.this.registry_id
  }
}
