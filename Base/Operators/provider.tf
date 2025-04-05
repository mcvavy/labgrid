terraform {
    required_version = ">= 1.0.0"
    required_providers {

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

    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.19.0"
    }

    external = {
      source  = "hashicorp/external"
      version = "2.3.4"
    }

    http = {
      source = "hashicorp/http"
      version = "3.4.5"
    }
  }

  backend "azurerm" {
    resource_group_name  = "labgrid"
    storage_account_name = "labgrid"
    container_name       = "labgridtfstate"
    key                  = "labgrid.operators.tfstate"
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

# Kubernetes provider using OIDC token
provider "kubernetes" {
  # config_path = "~/.kube/config" # Update with your kubeconfig path
  host  = var.k8s_host
  token = data.external.k8s_token.result.token
}

data "external" "k8s_token" {
  program = ["sh", "-c", <<-EOT
    token=$(curl -s ${var.keycloak_issuer_url}/protocol/openid-connect/token \
      -d client_id=${var.keycloak_client_id} \
      -d client_secret=${var.keycloak_client_secret} \
      -d grant_type=client_credentials | jq -r .access_token)
    echo "{\"token\":\"$token\"}"
  EOT
  ]
}

# Helm provider using OIDC token
provider "helm" {
  kubernetes {
    host  = var.k8s_host
    token = data.external.k8s_token.result.token
  }
}

# kubectl provider using OIDC token
provider "kubectl" {
  load_config_file = "false"
  host  = var.k8s_host
  token = data.external.k8s_token.result.token
}

provider "external" {}

provider "http" {}