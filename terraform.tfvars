aws_region = "us-east-2"

# Optional: change the name prefix
target_name = "jenkins-al2023-target"

instance_type = "t3.small"
key_name      = "ec2-jenkins-cicd"

# Recommended: lock these down to your IP (/32)
ssh_cidr = "0.0.0.0/0"
app_cidr = "0.0.0.0/0"
