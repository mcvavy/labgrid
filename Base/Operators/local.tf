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