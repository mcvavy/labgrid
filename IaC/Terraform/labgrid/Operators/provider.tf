terraform {
    required_version = ">= 1.0.0"
    required_providers {
    helm = {
        source  = "hashicorp/helm"
        version = "2.16.1"
    }
  }

  backend "azurerm" {
    resource_group_name  = "labgrid"
    storage_account_name = "labgrid"
    container_name       = "labgridtfstate"
    key                  = "labgrid.operators.tfstate"
  }
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config" # Update with your kubeconfig path
  }
}