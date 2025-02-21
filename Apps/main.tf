provider "argocd" {
  server_addr = "argocd.labgrid.net"
  username    = "admin"
  password    = var.argocdAdminPassword
}