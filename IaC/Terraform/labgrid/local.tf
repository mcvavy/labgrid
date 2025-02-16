locals {
  ingressNginxSettings = {
    name          = "ingress-nginx"
    namespace     = "ingress-nginx"
    chart_version = "4.12.0"
    repository    = "https://kubernetes.github.io/ingress-nginx"
  }

  metallbSettings = {
    name          = "metallb"
    namespace     = "metallb-system"
    version       = "0.14.9"
    repository    = "https://metallb.github.io/metallb"
    apiVersion    = "metallb.io/v1beta1"
  }

  traefikSettings = {
    name          = "traefik"
    namespace     = "traefik"
    chart_version = "34.3.0"
 }

  daprSettings = {
    name          = "dapr"
    dashboard     = "dapr-dashboard"
    namespace     = "dapr-system"
    chart_version = "1.11.3"
  }

  argocdSettings = {
    name          = "argo-cd"
    namespace     = "argocd"
    chart_version = "7.6.12"
    repository    = "https://argoproj.github.io/argo-helm"
  }

  certManagerSettings = {
    name          = "cert-manager"
    namespace     = "cert-manager"
    chart_version = "v1.17.0"
    repository    = "https://charts.jetstack.io"
  }

  clusterIssuerSettings = {
    //name          = var.environment == "prod" ? "letsencrypt-production" : "letsencrypt-staging"
    name          = "letsencrypt"
    server        = var.environment == "prod" ? "https://acme-v02.api.letsencrypt.org/directory" : "https://acme-staging-v02.api.letsencrypt.org/directory"
    namespace     = "cert-manager"
    apiVersion    = "cert-manager.io/v1"
    kind          = "ClusterIssuer"
    issuerRef     = "letsencrypt"
    dnsZones      = var.dnsZones
    email = var.letsencryptEmail
  }

  synologyCsiSettings = {
    name          = "synology-csi"
    namespace     = "synology-csi"
    chart_version = "0.10.1"
    repository    = "https://christian-schlichtherle.github.io/synology-csi-chart"
    clientIp      = var.synologyClientIp
    clientPort    = var.synologyClientPort
    serviceAccountUsername = var.synologyServiceAccountUsername
    serviceAccountPassword = var.synologyServiceAccountPassword
  }

  cloudNativePGSettings = {
    name          = "cloudnative-pg"
    namespace     = "cnpg-system"
    chart_version = "0.23.0"
    repository    = "https://cloudnative-pg.github.io/charts"
  }

  externalSecretsSettings = {
    name          = "external-secrets"
    namespace     = "external-secrets"
    repository    = "https://charts.external-secrets.io"
  }
}