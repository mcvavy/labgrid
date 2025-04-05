

resource "helm_release" "metallb" {
  name             = local.metallbSettings.name
  namespace        = local.metallbSettings.namespace
  create_namespace = true
  repository = local.metallbSettings.repository
  chart = local.metallbSettings.name
  version = local.metallbSettings.version

  wait = true
  timeout = 300
}

resource "helm_release" "cert_manager" {
  name             = local.certManagerSettings.name
  namespace        = local.certManagerSettings.namespace
  create_namespace = true

  repository = local.certManagerSettings.repository
  chart      = local.certManagerSettings.name
  version   = local.certManagerSettings.chart_version

  values = [ 
    file("${path.module}/values/cert-manager/values.yaml") 
    ]

  wait    = true
  timeout = 300
}

resource "helm_release" "external-secrets-operator" {
  name             = local.externalSecretsSettings.name
  namespace        = local.externalSecretsSettings.namespace
  create_namespace = true

  repository = local.externalSecretsSettings.repository
  chart      = local.externalSecretsSettings.name
  upgrade_install = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  wait = true
}

resource "helm_release" "cloudnative-pg-operator" {
  name             = local.cloudNativePGSettings.name
  repository       = local.cloudNativePGSettings.repository
  chart            = local.cloudNativePGSettings.name
  version          = local.cloudNativePGSettings.chart_version
  namespace        = local.cloudNativePGSettings.namespace
  create_namespace = true

  wait = true
}