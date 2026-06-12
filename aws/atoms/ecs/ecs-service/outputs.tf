output "manifest" {
  description = "All outputs of the ECS service atom, collected on a single object."
  value = {
    id          = aws_ecs_service.this.id
    name        = aws_ecs_service.this.name
    cluster_arn = aws_ecs_service.this.cluster
  }
}
