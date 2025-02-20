#!/bin/sh


environment="${1:-stg}"

set -e

rm -rf .terraform
terraform init -upgrade
terraform validate
terraform plan --var-file=variables-"$environment".tfvars
terraform apply --var-file=variables-"$environment".tfvars -auto-approve