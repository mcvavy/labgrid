# Kubernetes variables
variable "k8s_host" {
  type = string
  description = "Kubernetes host"
  default = "https://k8s-server.labgrid.net"
}

variable "k8s_token" {
  type = string
  description = "Kubernetes token"
}

variable "keycloak_issuer_url" {
  type        = string
  description = "Keycloak issuer URL"
  sensitive   = true
}

variable "keycloak_client_secret" {
  type        = string
  description = "Keycloak client secret"
  sensitive   = true
}

variable "keycloak_client_id" {
  type        = string
  description = "Keycloak client id"
  sensitive   = true
}