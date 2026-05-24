output "instance_id" {
  value = aws_eip.flask_eip.public_ip
}
