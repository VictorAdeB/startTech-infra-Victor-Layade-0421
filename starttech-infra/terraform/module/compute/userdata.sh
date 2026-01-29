#!/bin/bash
set -e

##################################
# SYSTEM UPDATE
##################################
yum update -y

##################################
# INSTALL DOCKER
##################################
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

##################################
# LOAD ENVIRONMENT VARIABLES
##################################
source /etc/environment

##################################
# PULL & RUN BACKEND CONTAINER
##################################
# CHANGE THIS TO YOUR IMAGE
DOCKER_IMAGE="victorade08/starttech-api:latest"

docker pull $DOCKER_IMAGE

docker run -d \
  --name starttech-api \
  --restart always \
  -p 80:8080 \
  -e MONGODB_URI="$MONGODB_URI" \
  -e REDIS_HOST="$REDIS_HOST" \
  -e REDIS_PORT="$REDIS_PORT" \
  $DOCKER_IMAGE

##################################
# BASIC HEALTH CHECK LOG
##################################
sleep 15
curl -f http://localhost/health || echo "Health check failed"

