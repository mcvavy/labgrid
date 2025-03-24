variable "letsencryptEmail" {
  description = "Email address for Let's Encrypt"
}

variable "azureServicePrincipalClientId" {
  description = "Azure service principal client id"
  sensitive = true
}

variable "azureServicePrincipalClientSecret" {
  description = "Azure service principal client secret"
  sensitive = true
}

variable "azureServicePrincipalTenantId" {
  description = "Azure service principal tenant id"
  sensitive = true
}

variable "azureSubscriptionId" {
  description = "Azure subscription id"
  sensitive = true
}

variable "azureKeyVaultUrl" {
  description = "Azure Key Vault URL"
  default = "https://labgrid.vault.azure.net"
}

variable "dnsZones" {
  description = "Cloudflare DNS zones"
}

variable "cloudflareApiTokenKey" {
  description = "Cloudflare API token key"
  sensitive = true
}

variable "traefik_dashboard_auth_users" {
  description = "Azure subscription id"
  sensitive = true
}

variable "synologyClientIp" {
  description = "Synology client IP"
}

variable "synologyClientPort" {
  description = "Synology client port"
}

variable "synologyServiceAccountUsername" {
  description = "Synology client username"
  sensitive = true
}

variable "synologyServiceAccountPassword" {
  description = "Synology client password"
  sensitive = true
}

variable "argocdServerAddress" {
  description = "ArgoCD server address"
  default = "argocd.labgrid.net"
}

variable "environment" {
  description = "Environment"
  validation {
    condition = contains(["stg", "prod"], var.environment)
    error_message = "Environment must be set"
  }
}

variable "k8s_host" {
  type = string
}

variable "k8s_token" {
  type = string
}