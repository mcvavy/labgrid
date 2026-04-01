terraform {
  required_providers {

    argocd = {
      source  = "argoproj-labs/argocd"
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
      version = "3.1.1"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "labgrid"
    storage_account_name = "labgrid"
    container_name       = "labgridtfstate"
    key                  = "labgrid.apps.tfstate"
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
  host  = var.k8s_host
  token = var.k8s_token
}

provider "helm" {
  kubernetes = {
    host  = var.k8s_host
    token = var.k8s_token
  }
}
