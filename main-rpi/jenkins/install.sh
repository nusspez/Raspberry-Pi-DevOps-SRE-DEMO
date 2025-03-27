#!/bin/bash
set -e  # Salir si algún comando falla
export DEBIAN_FRONTEND=noninteractive  # Evita confirmaciones interactivas

sudo apt update && sudo apt upgrade -y
sudo apt install -y openjdk-11-jdk
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl status jenkins
sudo cat /var/lib/jenkins/secrets/initialAdminPassword > ~/Desktop/initialAdminPasswordJenkins.txt