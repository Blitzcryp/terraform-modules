output "manifest" {
  description = "All outputs of the AWS Config recorder atom, collected on a single object."
  value = {
    recorder_name         = aws_config_configuration_recorder.this.name
    delivery_channel_name = aws_config_delivery_channel.this.name
    is_enabled            = aws_config_configuration_recorder_status.this.is_enabled
  }
}
