variable "letsencryptEmail" {
  description = "Email address for Let's Encrypt"
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

variable "environment" {
  description = "Environment"
  validation {
    condition = contains(["stg", "prod"], var.environment)
    error_message = "Environment must be set"
  }
}