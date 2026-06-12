output "manifest" {
  description = "All outputs of the ECS task definition atom, collected on a single object."
  value = {
    arn                  = aws_ecs_task_definition.this.arn
    arn_without_revision = aws_ecs_task_definition.this.arn_without_revision
    family               = aws_ecs_task_definition.this.family
    revision             = aws_ecs_task_definition.this.revision
  }
}
