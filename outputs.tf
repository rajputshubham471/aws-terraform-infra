# ============================================================
# outputs.tf — What Terraform prints after `terraform apply`
#
# Outputs are like "return values" from your infrastructure.
# After apply, you'll see these in the terminal.
# They can also be consumed by other Terraform configs.
# ============================================================

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "ec2_instance_ids" {
  description = "IDs of the EC2 instances"
  value       = module.ec2.instance_ids
}

output "ec2_public_ips" {
  description = "Public IP addresses of EC2 instances — use these to SSH in"
  value       = module.ec2.public_ips
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket created"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket (used for IAM policies)"
  value       = module.s3.bucket_arn
}

output "iam_role_name" {
  description = "Name of the IAM role attached to EC2 instances"
  value       = module.iam.role_name
}

# SSH connection helper — prints the exact command to connect
output "ssh_connect_commands" {
  description = "SSH commands to connect to your EC2 instances"
  value = [
    for ip in module.ec2.public_ips :
    "ssh -i ~/.ssh/${var.key_pair_name}.pem ec2-user@${ip}"
  ]
}
