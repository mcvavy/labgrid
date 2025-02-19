#!/bin/sh

set -e

# rm -rf .terraform
terraform init -upgrade
terraform validate
terraform plan
terraform apply -auto-approve