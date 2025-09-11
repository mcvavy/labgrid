locals {

  metallbSettings = {
    name          = "metallb"
    namespace     = "metallb-system"
    version       = "0.14.9"
    repository    = "https://metallb.github.io/metallb"
    apiVersion    = "metallb.io/v1beta1"
  }

  certManagerSettings = {
    name          = "cert-manager"
    namespace     = "cert-manager"
    chart_version = "v1.17.0"
    repository    = "https://charts.jetstack.io"
  }

  ingressNginxSettings = {
    name          = "ingress-nginx"
    namespace     = "ingress-nginx"
    chart_version = "4.12.0"
    repository    = "https://kubernetes.github.io/ingress-nginx"
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
    chart_version = "7.8.2"
    repository    = "https://argoproj.github.io/argo-helm"
  }

  clusterIssuerSettings = {
    nameStaging          = "letsencrypt-staging"
    nameProduction       = "letsencrypt-production"
    tranzrNameStaging          = "tranzr-letsencrypt-staging"
    tranzrNameProduction       = "tranzr-letsencrypt-production"
    stagingServer        = "https://acme-staging-v02.api.letsencrypt.org/directory"
    productionServer     = "https://acme-v02.api.letsencrypt.org/directory"
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

  pgAdminSettings = {
    name          = "pgadmin4"
    namespace     = "pg-admin-system"
    chart_version = "1.35.0"
    repository    = "https://helm.runix.net"
  }

  prometheusSettings = {
    name          = "kube-prometheus-stack"
    namespace     = "prometheus-system"
    chart_version = "70.3.0"
    repository    = "https://prometheus-community.github.io/helm-charts"
  }
}