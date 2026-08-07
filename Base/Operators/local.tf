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

  cloudNativePGSettings = {
    name          = "cloudnative-pg"
    namespace     = "cnpg-system"
    chart_version = "0.28.0"
    repository    = "https://cloudnative-pg.github.io/charts"
  }

  externalSecretsSettings = {
    name          = "external-secrets"
    namespace     = "external-secrets"
    chart_version = "2.2.0"
    repository    = "https://charts.external-secrets.io"
  }

  rabbitmqClusterOperatorSettings = {
    name          = "rabbitmq-cluster-operator"
    namespace     = "rabbitmq-system"
    chart_version = "0.5.5"
    repository    = "oci://registry-1.docker.io/cloudpirates"
    chart         = "rabbitmq-cluster-operator"
  }

  # Pins match Hetzner (NGF 2.5.0 → Gateway API v1.5.1).
  # Labgrid also installs experimental TCPRoute CRD for Forgejo SSH.
  nginxGatewayFabricSettings = {
    version             = "2.5.0"
    gateway_api_version = "v1.5.1"
  }
}
