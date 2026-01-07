# AWS Region
aws_region = "us-east-2"

# Name prefix for all target resources
target_name = "jenkins-al2023-target"

# EC2 configuration
instance_type = "t3.small"
key_name      = "ec2-jenkins-cicd"

# Networking
vpc_cidr           = "10.20.0.0/16"
public_subnet_cidr = "10.20.1.0/24"

# Security
# Recommended: lock these down to your public IP (/32)
ssh_cidr = "0.0.0.0/0"
app_cidr = "0.0.0.0/0"

