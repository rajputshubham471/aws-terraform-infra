# AWS Infrastructure Provisioning with Terraform

> **DevOps Portfolio Project 1** | Shubham Panwar 
> Provisions a production-style multi-tier AWS environment using Terraform modules, remote state, and IAM best practices.

---

## Architecture Overview

```
                        Internet
                           │
                    [Internet Gateway]
                           │
              ┌────────────────────────┐
              │     VPC 10.0.0.0/16    │
              │                        │
              │  ┌──────────────────┐  │
              │  │  Public Subnets  │  │
              │  │  10.0.1.0/24     │  │  ← EC2 Web Servers
              │  │  10.0.2.0/24     │  │    (Nginx, IAM Role)
              │  └──────────────────┘  │
              │           │            │
              │      [NAT Gateway]     │
              │           │            │
              │  ┌──────────────────┐  │
              │  │ Private Subnets  │  │
              │  │  10.0.10.0/24    │  │  ← Future: DB / App tier
              │  │  10.0.11.0/24    │  │
              │  └──────────────────┘  │
              └────────────────────────┘
                           │
                    [S3 Bucket] ← EC2 accesses via IAM Role (no hardcoded keys)
```

## Resources Created

| Resource | Count | Notes |
|---|---|---|
| VPC | 1 | Custom CIDR, DNS enabled |
| Public Subnets | 2 | One per AZ |
| Private Subnets | 2 | One per AZ |
| Internet Gateway | 1 | Enables public internet access |
| NAT Gateway | 1 | Outbound internet for private subnets |
| EC2 Instances | 2 | t2.micro (free tier), Nginx installed |
| S3 Bucket | 1 | Encrypted, versioned, private |
| IAM Role | 1 | EC2 → S3 access, least privilege |
| Security Group | 1 | Ports 22, 80, 443 open |

---

## Prerequisites

- [Terraform >= 1.5.0](https://developer.hashicorp.com/terraform/install)
- [AWS CLI](https://aws.amazon.com/cli/) configured (`aws configure`)
- AWS account (free tier works)
- An EC2 key pair in your region

---

## Step-by-Step Setup

### Step 1: Configure AWS CLI

```bash
aws configure
# AWS Access Key ID: [your key]
# AWS Secret Access Key: [your secret]
# Default region: ap-south-1
# Default output format: json

# Verify it works
aws sts get-caller-identity
```

### Step 2: Create Remote State Backend (One-Time Setup)

Before running Terraform, manually create the S3 bucket and DynamoDB table for remote state:

```bash
# Create S3 bucket for state (MUST be globally unique — change the name!)
aws s3api create-bucket \
  --bucket shubhammansi321-tf-state-bucket \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning on state bucket (so you can recover old states)
aws s3api put-bucket-versioning \
  --bucket shubhammansi321-tf-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
# (Prevents two people from running terraform apply simultaneously)
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

### Step 3: Create EC2 Key Pair

```bash
# Create key pair and save the private key
aws ec2 create-key-pair \
  --key-name Shubham-devops-key \
  --query 'KeyMaterial' \
  --output text > ~/.ssh/Shubham-devops-key.pem

# Set correct permissions (required for SSH)
chmod 400 ~/.ssh/Shubham-devops-key.pem
```

### Step 4: Clone and Configure

```bash
git clone https://github.com/YOUR_USERNAME/aws-terraform-infra.git
cd aws-terraform-infra

# Copy and edit the variables file
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values (region, key name, etc.)
```

### Step 5: Deploy

```bash
# Initialize — downloads providers, sets up backend
terraform init

# Preview what will be created (ALWAYS do this before apply)
terraform plan

# Deploy!
terraform apply
# Type 'yes' when prompted

# After apply, you'll see outputs like:
# ec2_public_ips = ["15.206.x.x", "15.206.x.x"]
# s3_bucket_name = "Shubham-devops-dev-a3f2b1c9"
# ssh_connect_commands = ["ssh -i ~/.ssh/Shubham-devops-key.pem ec2-user@15.206.x.x"]
```

### Step 6: Verify

```bash
# SSH into an instance
ssh -i ~/.ssh/Shubham-devops-key.pem ec2-user@<PUBLIC_IP>

# Check nginx is running
sudo systemctl status nginx

# Test S3 access from EC2 (uses IAM role — no credentials needed!)
aws s3 ls s3://<BUCKET_NAME>
echo "Hello from Terraform EC2" > test.txt
aws s3 cp test.txt s3://<BUCKET_NAME>/test.txt
aws s3 ls s3://<BUCKET_NAME>

# Check user data logs
cat /var/log/user-data.log

# Exit EC2
exit

# Test HTTP from your machine
curl http://<PUBLIC_IP>
```

### Step 7: Clean Up (Avoid Charges!)

```bash
# IMPORTANT: Always destroy resources when done to avoid AWS charges
terraform destroy
# Type 'yes' when prompted

# NAT Gateway costs ~$32/month even when idle — always destroy!
```

---

## Key Concepts Demonstrated

| Concept | Where Used |
|---|---|
| **DRY Principle** | Variables used instead of hardcoded values |
| **Modules** | VPC, EC2, S3, IAM split into reusable modules |
| **Remote State** | S3 backend with DynamoDB locking |
| **Least Privilege IAM** | EC2 only gets access to its own S3 bucket |
| **count meta-argument** | Creates multiple subnets/EC2s from one resource block |
| **Output values** | SSH commands printed after apply |
| **Lifecycle rules** | S3 auto-deletes old versions |
| **User data** | EC2 auto-configures on first boot |

---

## Common Issues & Fixes

**Error: Bucket name already exists**
→ S3 bucket names are global. Change `project_name` in tfvars to something unique.

**Error: InvalidAMIID**
→ AMI IDs are region-specific. Find the correct ID:
```bash
aws ec2 describe-images --owners amazon \
  --filters "Name=name,Values=al2023-ami-*" \
  --query 'sort_by(Images,&CreationDate)[-1].ImageId' \
  --output text
```

**Error: KeyPair does not exist**
→ Create the key pair first (Step 3 above) or update `key_pair_name` in tfvars.

**SSH connection refused**
→ Wait 2-3 minutes after `terraform apply` for user data to finish.

---

## Tech Stack

`Terraform 1.5+` · `AWS EC2` · `AWS VPC` · `AWS S3` · `AWS IAM` · `AWS DynamoDB` · `Amazon Linux 2023` · `Nginx`

---

## Author

**Shubham Sharma** — Associate DevOps Engineer  
[GitHub](https://github.com/Shubhamsharma) · [LinkedIn](https://linkedin.com/in/Shubhamsharma)