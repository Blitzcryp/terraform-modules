output "manifest" {
  description = "All outputs of the Step Functions state machine atom, collected on a single object."
  value = {
    arn           = aws_sfn_state_machine.this.arn
    name          = aws_sfn_state_machine.this.name
    creation_date = aws_sfn_state_machine.this.creation_date
  }
}
