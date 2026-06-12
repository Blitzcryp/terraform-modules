output "manifest" {
  description = "All outputs of the ECS cluster atom, collected on a single object."
  value = {
    id   = aws_ecs_cluster.this.id
    arn  = aws_ecs_cluster.this.arn
    name = aws_ecs_cluster.this.name
  }
}
