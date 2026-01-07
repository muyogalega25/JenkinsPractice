variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "us-east-2"
}

variable "target_name" {
  type        = string
  description = "Name prefix for target resources created/destroyed by Terraform"
  default     = "jenkins-al2023-target"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the target instance"
  default     = "t3.small"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 Key Pair name for SSH access"
  default     = "ec2-jenkins-cicd"
}

variable "ssh_cidr" {
  type        = string
  description = "CIDR allowed to SSH (port 22) to the target instance. Recommended: your_public_ip/32"
  default     = "0.0.0.0/0"
}

variable "app_cidr" {
  type        = string
  description = "CIDR allowed to access the target app on port 8080. Recommended: your_public_ip/32"
  default     = "0.0.0.0/0"
}

variable "availability_zone_suffix" {
  type        = string
  description = "Availability Zone suffix, e.g. 'a' makes us-east-2a"
  default     = "a"
}

variable "tags" {
  type        = map(string)
  description = "Common tags applied to resources"
  default = {
    ManagedBy = "Terraform"
    Project   = "JenkinsPractice"
  }
}