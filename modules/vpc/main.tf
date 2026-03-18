# ============================================================
# modules/vpc/main.tf
#
# This module creates the complete network layer:
#
#   Internet
#      │
#  [IGW] ← Internet Gateway (allows internet traffic in/out)
#      │
#  [VPC 10.0.0.0/16]
#   ├── Public Subnet AZ-a  (10.0.1.0/24)  ← Web servers, load balancers
#   ├── Public Subnet AZ-b  (10.0.2.0/24)
#   ├── Private Subnet AZ-a (10.0.10.0/24) ← Databases, app servers
#   └── Private Subnet AZ-b (10.0.11.0/24)
#                │
#             [NAT GW] ← Lets private subnets reach internet (outbound only)
#
# ARCHITECTURE PRINCIPLE:
# Public subnets = resources that need to be reachable from internet
# Private subnets = resources that should NOT be directly reachable
# ============================================================

# ── VPC ──────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true   # Gives EC2 instances DNS names like ec2-x-x-x-x.compute.amazonaws.com
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc"
  }
}

# ── Internet Gateway ─────────────────────────────────────────
# The "door" between your VPC and the public internet
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-${var.environment}-igw"
  }
}

# ── Public Subnets ───────────────────────────────────────────
# count = length(...) creates one subnet per AZ automatically
# count.index lets us pick the right CIDR and AZ for each
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true   # EC2s here get a public IP automatically

  tags = {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Tier = "Public"
  }
}

# ── Private Subnets ──────────────────────────────────────────
resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  # No map_public_ip_on_launch — these stay private

  tags = {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Tier = "Private"
  }
}

# ── Elastic IP for NAT Gateway ───────────────────────────────
# NAT Gateway needs a static public IP
resource "aws_eip" "nat" {
  domain = "vpc"

#tags = {
#    Name = "${var.project_name}-${var.environment}-nat-eip"
#  }
#
#  # Must wait for IGW to exist before creating EIP
#  depends_on = [aws_internet_gateway.main]
#}
#
# ── NAT Gateway ──────────────────────────────────────────────
# Sits in a PUBLIC subnet, lets PRIVATE subnet instances
# make outbound internet requests (e.g., yum update, pip install)
# without being directly reachable from the internet
#resource "aws_nat_gateway" "main" {
#  allocation_id = aws_eip.nat.id
#  subnet_id     = aws_subnet.public[0].id   # NAT GW lives in first public subnet
#
#  tags = {
#    Name = "${var.project_name}-${var.environment}-nat-gw"
#  }
#}

# ── Public Route Table ───────────────────────────────────────
# Rules: "all traffic (0.0.0.0/0) → go out through the IGW"
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-public-rt"
  }
}

# Associate public route table with each public subnet
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ── Private Route Table ──────────────────────────────────────
# Rules: "all outbound traffic → go through NAT Gateway"
#resource "aws_route_table" "private" {
#  vpc_id = aws_vpc.main.id
#
#  route {
#    cidr_block     = "0.0.0.0/0"
#    nat_gateway_id = aws_nat_gateway.main.id
#  }
#
#  tags = {
#    Name = "${var.project_name}-${var.environment}-private-rt"
#  }
#}
#
# Associate private route table with each private subnet
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
