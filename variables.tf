variable "aws_region" {
  type        = string
  description = "AWS region to deploy into"
  default     = "us-east-2"
}

variable "target_name" {
  type        = string
  description = "Name prefix for resources created and destroyed by Terraform"
  default     = "jenkins-target"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the target instance"
  default     = "t3.small"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 Key Pa
