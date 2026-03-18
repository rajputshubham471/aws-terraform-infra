# ============================================================
# terraform.tfvars.example
#
# This file shows you how to OVERRIDE the default values
# from variables.tf without changing the variable definitions.
#
# HOW TO USE:
#   1. Copy this file:  cp terraform.tfvars.example terraform.tfvars
#   2. Edit the values to match your setup
#   3. Run terraform plan
#
# IMPORTANT: Never commit terraform.tfvars to Git if it
# contains sensitive values (add it to .gitignore)
# ============================================================

aws_region   = "ap-south-1"
project_name = "shubham-devops"
environment  = "dev"

# Networking
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]
availability_zones   = ["ap-south-1a", "ap-south-1b"]

# EC2 — CHANGE ami_id if deploying to a different region!
ami_id         = "ami-019715e0d74f695be"   # Amazon Linux 2023 — Mumbai
instance_type  = "t2.micro"                # Free tier eligible
key_pair_name  = "project1"        # Must exist in your AWS account
