variable "argocdAdminPassword" {
  description = "ArgoCD admin password"
  sensitive = true
}

variable "k8s_host" {
  type = string
}

variable "k8s_token" {
  type = string
}