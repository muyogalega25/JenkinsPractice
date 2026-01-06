variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "Jenkins-server2" {
  type    = string
  default = "jenkins-al2023"
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "key_name" {
  type        = string
  description = "ec2-jenkins-cicd"
}

variable "my_ip_cidr" {
  type        = string
  description = "0.0.0.0/0"
}

# For quick demo you can leave Jenkins open to the world (0.0.0.0/0),
# but safer is to restrict it to your IP or VPN CIDR.
variable "jenkins_cidr" {
  type        = string
  description = "CIDR allowed to access Jenkins 8080"
  default     = "0.0.0.0/0"
}
