locals {

  metallbSettings = {
    name       = "metallb"
    namespace  = "metallb-system"
    version    = "0.14.9"
    repository = "https://metallb.github.io/metallb"
    apiVersion = "metallb.io/v1beta1"
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
    # argo-helm 10.2.2 → Argo CD v3.4.6 (k8s client schema covers 1.36 fields
    # such as Deployment.status.terminatingReplicas; required for ServerSideApply).
    chart_version = "10.2.2"
    repository    = "https://argoproj.github.io/argo-helm"
  }

  clusterIssuerSettings = {
    nameStaging          = "letsencrypt-staging"
    nameProduction       = "letsencrypt-production"
    tranzrNameStaging    = "tranzr-letsencrypt-staging"
    tranzrNameProduction = "tranzr-letsencrypt-production"
    stagingServer        = "https://acme-staging-v02.api.letsencrypt.org/directory"
    productionServer     = "https://acme-v02.api.letsencrypt.org/directory"
    namespace            = "cert-manager"
    apiVersion           = "cert-manager.io/v1"
    kind                 = "ClusterIssuer"
    issuerRef            = "letsencrypt"
    dnsZones             = var.dnsZones
    email                = var.letsencryptEmail
  }

  synologyCsiSettings = {
    name                   = "synology-csi"
    namespace              = "synology-csi"
    chart_version          = "0.11.3"
    repository             = "https://christian-schlichtherle.github.io/synology-csi-chart"
    clientIp               = var.synologyClientIp
    clientPort             = var.synologyClientPort
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

  # Match Hetzner NGF pin (Gateway API CRDs installed in Base/Operators).
  # NGF 2.x provisions one LoadBalancer Service per Gateway — keep a single
  # labgrid-gateway on .205 and add extra listeners for other wildcards.
  nginxGatewayFabricSettings = {
    name             = "ngf"
    namespace        = "nginx-gateway"
    chart            = "nginx-gateway-fabric"
    chart_version    = "2.5.0"
    repository       = "oci://ghcr.io/nginx/charts"
    load_balancer_ip = "192.168.1.205"
    gateway_name     = "labgrid-gateway"
    gateway_hostname = "*.labgrid.net"
    tls_secret_name  = "labgrid-wildcard-tls"
    cluster_issuer   = "letsencrypt-production"

    # Staging *.tranzrmoves.com listeners on the same Gateway (separate Certificate).
    tranzrmoves_http_listener    = "http-tranzrmoves"
    tranzrmoves_https_listener   = "https-tranzrmoves"
    tranzrmoves_gateway_hostname = "*.tranzrmoves.com"
    tranzrmoves_tls_secret_name  = "tranzrmoves-wildcard-tls"
    tranzrmoves_cluster_issuer   = "tranzr-letsencrypt-production"

    # Forgejo Git SSH (TCPRoute) on the shared Gateway VIP.
    forgejo_ssh_listener = "forgejo-ssh"
    forgejo_ssh_port     = 2222
  }
}
