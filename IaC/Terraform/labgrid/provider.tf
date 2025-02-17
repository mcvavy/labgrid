terraform {
    required_version = ">= 1.0.0"
    required_providers {

    argocd = {
      source = "argoproj-labs/argocd"
      version = "7.3.1"
    }

    azurerm = {
        source  = "hashicorp/azurerm"
        version = "~>4.0"
    }

    kubernetes = {
        source  = "hashicorp/kubernetes"
        version = "2.33.0"
    }

    helm = {
        source  = "hashicorp/helm"
        version = "2.16.1"
    }

    null = {
        source  = "hashicorp/null"
        version = "3.2.3"
    }

    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "labgrid"
    storage_account_name = "labgrid"
    container_name       = "labgridtfstate"
    key                  = "labgrid.tfstate"
  }
}

provider "azurerm" {
  resource_provider_registrations = "all"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config" # Update with your kubeconfig path
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config" # Update with your kubeconfig path
  }
}

provider "kubectl" {
    config_path = "~/.kube/config" # Update with your kubeconfig path
}

provider "argocd" {
  server_addr = var.argocdServerAddress
  auth_token  = var.argocdAuthToken
}