# modules/ec2/outputs.tf

output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.web[*].id
}

output "public_ips" {
  description = "List of public IP addresses"
  value       = aws_instance.web[*].public_ip
}

output "private_ips" {
  description = "List of private IP addresses"
  value       = aws_instance.web[*].private_ip
}

output "security_group_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web.id
}
