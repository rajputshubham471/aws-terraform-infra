# ============================================================
# variables.tf — Declare ALL input variables here
#
# WHY VARIABLES?
# Instead of hardcoding "ap-south-1" everywhere, you define
# it once here and reference var.aws_region across all files.
# This is the "DRY" (Don't Repeat Yourself) principle.
# Change one value → it updates everywhere automatically.
# ============================================================

variable "aws_region" {
  description = "AWS region to deploy all resources"
  type        = string
  default     = "ap-south-1"   # Mumbai — closest to Delhi
}

variable "project_name" {
  description = "Name prefix for all resources (used in naming and tagging)"
  type        = string
  default     = "shubham-devops"
}

variable "environment" {
  description = "Deployment environment: dev | staging | prod"
  type        = string
  default     = "dev"

  # Validation block — Terraform will ERROR if you pass an invalid value
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# ── Networking ────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the VPC. /16 gives 65,536 IPs."
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  # /24 = 256 IPs per subnet (AWS reserves 5, so 251 usable)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "availability_zones" {
  description = "AZs to deploy subnets into (must match region)"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]
}

# ── EC2 ───────────────────────────────────────────────────────
variable "ami_id" {
  description = "Amazon Machine Image ID. Free tier: Amazon Linux 2023 in ap-south-1"
  type        = string
  default     = "ami-019715e0d74f695be"   # Amazon Linux 2023 — Mumbai region
  # TIP: Find latest AMI: aws ec2 describe-images --owners amazon --filters "Name=name,Values=al2023-ami-*"
}

variable "instance_type" {
  description = "EC2 instance size. t2.micro is FREE TIER eligible."
  type        = string
  default     = "t2.micro"
}

variable "key_pair_name" {
  description = "Name of existing EC2 key pair for SSH access. Create in AWS Console first."
  type        = string
  default     = "project1"
  # Create with: aws ec2 create-key-pair --key-name shubham-devops-key --query 'KeyMaterial' --output text > shubham-devops-key.pem
}
