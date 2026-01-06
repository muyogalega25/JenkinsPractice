output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8080"
}

output "ssh_command" {
  value = "ssh -i \"C:/Users/galeg/Downloads/ec2-jenkins-cicd.pem\" ec2-user@${aws_instance.jenkins.public_ip}"
}


