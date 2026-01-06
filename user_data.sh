#!/bin/bash
set -euxo pipefail

dnf -y update

# Jenkins needs Java
dnf -y install java-17-amazon-corretto wget git

# Add Jenkins repo
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

dnf -y install jenkins

systemctl enable jenkins
systemctl start jenkins

# Optional: make sure it listens on 8080 (default)
# sed -i 's/^JENKINS_PORT=.*/JENKINS_PORT="8080"/' /etc/sysconfig/jenkins
# systemctl restart jenkins
