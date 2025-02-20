resource "kubernetes_manifest" "metallb_ipaddresspool" {
  manifest = {
    apiVersion = local.metallbSettings.apiVersion
    kind       = "IPAddressPool"
    metadata = {
      name      = "cluster-pool"
      namespace = local.metallbSettings.namespace
    }
    spec = {
      addresses = ["192.168.1.204-192.168.1.254"]
    }
  }
}

resource "kubernetes_manifest" "metallb_l2advertisement" {

  manifest = {
    apiVersion = local.metallbSettings.apiVersion
    kind       = "L2Advertisement"
    metadata = {
      name      = "cluster-pool-l2"
      namespace = local.metallbSettings.namespace
    }
    spec = {
      ipAddressPools = ["cluster-pool"]
    }
  }

  depends_on = [
    kubernetes_manifest.metallb_ipaddresspool
  ]
}

resource "helm_release" "ingress_nginx" {
  name       = local.ingressNginxSettings.name
  repository = local.ingressNginxSettings.repository
  chart      = local.ingressNginxSettings.name
  version    = local.ingressNginxSettings.chart_version

  namespace        = local.ingressNginxSettings.namespace
  create_namespace = true

  depends_on = [kubernetes_manifest.metallb_l2advertisement]
}

resource "kubernetes_secret_v1" "cloudflare_token_secret" {
  depends_on = [ kubernetes_manifest.metallb_l2advertisement ]

  metadata {
    name = "cloudflare-token-secret"
    namespace = "${local.certManagerSettings.namespace}"
  }

  data = {
    cloudflare-token: "${var.cloudflareApiTokenKey}"
  }

  type = "Opaque"
}

resource "kubernetes_manifest" "letsencrypt" {
  depends_on = [kubernetes_secret_v1.cloudflare_token_secret]

  manifest = {
    apiVersion = local.clusterIssuerSettings.apiVersion
    kind       = local.clusterIssuerSettings.kind
    metadata = {
      name = local.clusterIssuerSettings.name
    }
    spec = {
      acme = {
        server  = local.clusterIssuerSettings.server
        email   = local.clusterIssuerSettings.email
        privateKeySecretRef = {
          name = local.clusterIssuerSettings.name
        }
        solvers = [{
          dns01 = {
            cloudflare = {
              email = local.clusterIssuerSettings.email
              apiTokenSecretRef = {
                name = "cloudflare-token-secret"
                key  = "cloudflare-token"
              }
            }
          }
          selector = {
            dnsZones = [var.dnsZones]
          }
        }]
      }
    }
  }
}

resource "helm_release" "dapr" {
  name             = local.daprSettings.name
  repository       = "https://dapr.github.io/helm-charts"
  chart            = local.daprSettings.name
  namespace        = local.daprSettings.namespace
  version          = local.daprSettings.chart_version
  create_namespace = true

  timeout = 600
  wait    = true
}

resource "helm_release" "dapr-dashboard" {
  name             = local.daprSettings.dashboard
  repository       = "https://dapr.github.io/helm-charts"
  chart            = local.daprSettings.dashboard
  namespace        = local.daprSettings.namespace
  create_namespace = true

  timeout = 600
  wait    = true

  depends_on = [helm_release.dapr]
}

resource "kubernetes_manifest" "synology-csi-namespace" {
  manifest = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = local.synologyCsiSettings.namespace
    }
  }
}

# resource "kubectl_manifest" "client-info-secret" {
#     yaml_body = <<YAML
# apiVersion: v1
# kind: Secret
# metadata:
#   name: client-info-secret
#   namespace: ${local.synologyCsiSettings.namespace}
# type: Opaque
# stringData:
#   client-info.yaml: |
#     clients:
#     - host: ${local.synologyCsiSettings.clientIp}
#       port: ${local.synologyCsiSettings.clientPort}
#       https: true
#       username: ${local.synologyCsiSettings.serviceAccountUsername}
#       password: ${local.synologyCsiSettings.serviceAccountPassword}
# YAML
# depends_on = [kubernetes_manifest.synology-csi-namespace]
# }

resource "kubernetes_secret_v1" "client-info-secret" {
  metadata {
    name = "client-info-secret"
  }

  data = {
    host = local.synologyCsiSettings.clientIp
    port = local.synologyCsiSettings.clientPort
    https = true
    username = local.synologyCsiSettings.serviceAccountUsername
    password = local.synologyCsiSettings.serviceAccountPassword
  }

  type = "Opaque"

  depends_on = [kubernetes_manifest.synology-csi-namespace]
}


resource "helm_release" "synology-csi-chart" {
  name             = local.synologyCsiSettings.name
  repository       = local.synologyCsiSettings.repository
  chart            = local.synologyCsiSettings.name
  version          = local.synologyCsiSettings.chart_version
  namespace        = local.synologyCsiSettings.namespace

  values = [ 
    file("${path.module}/values/synology/values.yaml") 
    ]

  wait = true
  timeout = 300

  depends_on = [kubernetes_secret_v1.client-info-secret]
}

resource "kubernetes_storage_class_v1" "synology-iscsi-delete" {
  metadata {
    name = "synology-iscsi-delete"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "csi.san.synology.com"
  reclaim_policy      = "Delete"
  allow_volume_expansion = true
  parameters = {
    dsm = var.synologyClientIp
    fsType: "btrfs"
    location = "/volume1"
    protocol = "iscsi"
    formatOptions = "--nodiscard"
  }
}

resource "helm_release" "argocd" {
  depends_on = [ kubernetes_manifest.metallb_l2advertisement ]

  name             = local.argocdSettings.name
  repository       = local.argocdSettings.repository
  chart            = local.argocdSettings.name
  namespace        = local.argocdSettings.namespace
  version          = local.argocdSettings.chart_version
  create_namespace = true

  values = [ 
    file("${path.module}/values/argocd/values.yaml") 
    ]
}

resource "kubernetes_secret_v1" "azure-secret-sp-secret" {
  metadata {
    name = "azure-secret-sp-secret"
  }

  data = {
    clientId = "${var.azureServicePrincipalClientId}"
    clientSecret = "${var.azureServicePrincipalClientSecret}"
  }

  type = "Opaque"
}

resource "kubernetes_manifest" "azure-kv-cluster-store" {
  depends_on = [kubernetes_secret_v1.azure-secret-sp-secret]

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterSecretStore"
    metadata = {
      name = "azure-kv-cluster-store"
    }
    spec = {
      provider = {
        azurekv = {
          tenantId = var.azureServicePrincipalTenantId
          vaultUrl = var.azureKeyVaultUrl
          authSecretRef = {
            # points to the secret that contains
            # the azure service principal credentials
            clientId = {
              name = "azure-secret-sp-secret"
              key = "clientId"
              namespace = "default"
            }
            clientSecret = {
              name = "azure-secret-sp-secret"
              key = "clientSecret"
              namespace = "default"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_manifest" "postgres_cluster_superuser" {
  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ClusterExternalSecret"
    metadata = {
      name = "postgres-cluster-superuser"
    }
    spec = {
      externalSecretName = "postgres-superuser-external-secret"
      refreshTime        = "1h"

      externalSecretSpec = {
        secretStoreRef = {
          name = "azure-kv-cluster-store"
          kind = "ClusterSecretStore"
        }
        refreshInterval = "36h"
        target = {
          name     = "postgres-superuser-secret"
          template = {
            type = "kubernetes.io/basic-auth"
          }
        }
        data = [
          {
            secretKey = "username"
            remoteRef = {
              key = "postgres-super-user"
            }
          },
          {
            secretKey = "password"
            remoteRef = {
              key = "postgres-super-user-password"
            }
          }
        ]
      }
    }
  }
}
