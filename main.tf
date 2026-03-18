# ============================================================
# ROOT main.tf — Entry point for the entire infrastructure
# This file "wires" all modules together.
# Think of modules like functions: you define them once,
# call them here, and pass in the values they need.
# ============================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # REMOTE STATE — keeps your tfstate file in S3 (not local)
  # This is production best practice.
  # Before first `terraform init`, manually create the S3 bucket
  # and DynamoDB table (see README.md Step 2).
  backend "s3" {
    bucket         = "shubhammansi321-tf-state-bucket"        # CHANGE THIS to your unique bucket name
    key            = "aws-infra/terraform.tfstate"
    region         = "ap-south-1"         # For state locking (prevents concurrent runs)
    encrypt        = true                           # Encrypts state file at rest
  }
}

# ── AWS Provider ──────────────────────────────────────────────
# Tells Terraform which AWS region to deploy into.
# Credentials come from ~/.aws/credentials or env vars.
provider "aws" {
  region = var.aws_region

  # Tags applied to EVERY resource automatically — great practice
  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Shubham  panwar"
    }
  }
}

# ── MODULE: VPC ───────────────────────────────────────────────
# Creates the network foundation:
# 1 VPC → 2 public subnets → 2 private subnets
# Internet Gateway, Route Tables, NAT Gateway
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
}

# ── MODULE: IAM ───────────────────────────────────────────────
# Creates an IAM role + instance profile so EC2 can
# talk to S3 without hardcoded credentials (best practice)
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  s3_bucket_arn = module.s3.bucket_arn   # EC2 gets read/write access to THIS bucket only
}

# ── MODULE: S3 ────────────────────────────────────────────────
# Creates a private S3 bucket with:
# - Versioning enabled (recover from accidental deletes)
# - Server-side encryption (AES-256)
# - Public access fully blocked
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  environment  = var.environment
}

# ── MODULE: EC2 ───────────────────────────────────────────────
# Launches EC2 instances in public subnets (web tier)
# Attaches the IAM role from the IAM module
module "ec2" {
  source = "./modules/ec2"

  project_name        = var.project_name
  environment         = var.environment
  ami_id              = var.ami_id
  instance_type       = var.instance_type
  public_subnet_ids   = module.vpc.public_subnet_ids
  vpc_id              = module.vpc.vpc_id
  iam_instance_profile = module.iam.instance_profile_name
  key_pair_name       = var.key_pair_name
}
