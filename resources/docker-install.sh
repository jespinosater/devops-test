#!/bin/bash
groupadd docker
usermod -aG docker ubuntu
apt-get update
apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
apt-get update
apt-get -y install docker-ce
touch /tmp/docker_installed
