terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_region" "current" {}

locals {
  name_prefix = var.target_name

  # Safer AZ construction (works even if someone changes region var)
  az = "${data.aws_region.current.name}${var.availability_zone_suffix}"

  common_tags = merge(
    var.tags,
    {
      NamePrefix = local.name_prefix
      ManagedBy  = "Terraform"
      Project    = "JenkinsPractice"
    }
  )
}

# -------------------------
# AMI
# -------------------------
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# -------------------------
# VPC + Networking
# -------------------------
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = local.az

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-subnet"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

resource "aws_route" "default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id

  # Make the dependency explicit to avoid timing edge cases
  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# -------------------------
# Security Group (Target)
# -------------------------
resource "aws_security_group" "target" {
  name        = "${local.name_prefix}-sg"
  description = "Allow SSH and app access"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }

  ingress {
    description = "App (8080)"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [var.app_cidr]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-sg"
  })
}

# -------------------------
# IAM Role for Target EC2 (Optional)
# NOTE: This role is for the target instance itself.
# It does NOT grant Terraform permissions.
# -------------------------
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "target_role" {
  name               = "${local.name_prefix}-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-role"
  })
}

resource "aws_iam_instance_profile" "target_instance_profile" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.target_role.name

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-instance-profile"
  })
}

# -------------------------
# Target EC2 Instance
# -------------------------
resource "aws_instance" "target" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.target.id]
  key_name               = var.key_name

  iam_instance_profile = aws_iam_instance_profile.target_instance_profile.name

  user_data                  = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  # IMDSv2 recommended
  metadata_options {
    http_tokens = "required"
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-ec2"
  })

  # OPTIONAL safety net:
  # Uncomment if you want to ensure this resource is never destroyed by accident
 # lifecycle {
  #  prevent_destroy = true
   #}
}
