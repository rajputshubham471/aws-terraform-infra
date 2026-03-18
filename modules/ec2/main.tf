# ============================================================
# modules/ec2/main.tf
#
# Creates:
# - Security Group (firewall rules for the instances)
# - EC2 instances (one per public subnet)
# - User data script (runs on first boot — installs packages)
#
# SECURITY GROUP = virtual firewall for EC2
# Inbound rules  = what traffic can COME IN
# Outbound rules = what traffic can GO OUT
# ============================================================

# ── Security Group ───────────────────────────────────────────
resource "aws_security_group" "web" {
  name        = "${var.project_name}-${var.environment}-web-sg"
  description = "Security group for web server EC2 instances"
  vpc_id      = var.vpc_id

  # Allow SSH from anywhere (restrict to your IP in production!)
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    # PRODUCTION TIP: Replace with your IP: ["YOUR.IP.ADDRESS/32"]
  }

  # Allow HTTP traffic
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS traffic
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (needed for yum updates, etc.)
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"   # -1 means ALL protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-web-sg"
  }
}

# ── EC2 Instances ─────────────────────────────────────────────
# Creates one instance per public subnet (one per AZ)
resource "aws_instance" "web" {
  count = length(var.public_subnet_ids)

  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.web.id]
  key_name               = var.key_pair_name
  iam_instance_profile   = var.iam_instance_profile   # Attaches IAM role

  
  