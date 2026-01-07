output "target_public_ip" {
  description = "Public IP of the target EC2 instance"
  value       = aws_instance.target.public_ip
}

output "target_url" {
  description = "URL to access the target instance on port 8080"
  value       = "http://${aws_instance.target.public_ip}:8080"
}

output "ssh_command" {
  description = "SSH command (update the pem path on your machine)"
  value       = "ssh -i \"<PATH_TO_YOUR_PEM_FILE>\" ec2-user@${aws_instance.target.public_ip}"
}



