output "manifest" {
  description = "All outputs of the EC2 instance atom, collected on a single object."
  value = {
    id                           = aws_instance.this.id
    arn                          = aws_instance.this.arn
    private_ip                   = aws_instance.this.private_ip
    public_ip                    = aws_instance.this.public_ip
    primary_network_interface_id = aws_instance.this.primary_network_interface_id
    availability_zone            = aws_instance.this.availability_zone
  }
}
