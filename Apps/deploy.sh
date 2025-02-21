#!/bin/sh

set -e

rm -rf .terraform
terraform init -upgrade
terraform validate
terraform plan -var-file=variables.tfvars
terraform apply -var-file=variables.tfvars -auto-approve