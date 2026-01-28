#!/bin/bash
set -e

echo "Initializing Terraform..."
cd terraform
terraform init

echo "Validating Terraform..."
terraform validate

echo "Applying Infrastructure..."
terraform apply -auto-approve

echo "Infrastructure deployment complete"
