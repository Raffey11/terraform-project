#!/bin/bash
sudo yum update && sudo yum install docker -y
sudo systemctl start docker
sudo usermod -aG docker ec2-user
docker run -d -p8080:80 nginx