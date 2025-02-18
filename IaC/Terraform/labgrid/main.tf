

resource "helm_release" "metallb" {
  name             = local.metallbSettings.name
  namespace        = local.metallbSettings.namespace
  create_namespace = true
  repository = local.metallbSettings.repository
  chart = local.metallbSettings.name
  version = local.metallbSettings.version
}

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

    depends_on = [
    helm_release.metallb
  ]
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
    helm_release.metallb,
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


resource "helm_release" "cert_manager" {
  name             = local.certManagerSettings.name
  namespace        = local.certManagerSettings.namespace
  create_namespace = true

  repository = local.certManagerSettings.repository
  chart      = local.certManagerSettings.name
  version   = local.certManagerSettings.chart_version

  set {
    name  = "installCRDs"
    value = "true"
  }

  values = [ 
    file("${path.module}/values/cert-manager/values.yaml") 
    ]

  wait    = true
  timeout = 300

  depends_on = [ helm_release.ingress_nginx ]
}

resource "kubectl_manifest" "cloudflare_token_secret" {
    yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: cloudflare-token-secret
  namespace: ${local.certManagerSettings.namespace}
type: Opaque
stringData:
  cloudflare-token: ${var.cloudflareApiTokenKey}
YAML
depends_on = [helm_release.cert_manager]
}

resource "kubernetes_manifest" "letsencrypt" {
  depends_on = [kubectl_manifest.cloudflare_token_secret]

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

resource "kubectl_manifest" "client-info-secret" {
    yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: client-info-secret
  namespace: ${local.synologyCsiSettings.namespace}
type: Opaque
stringData:
  client-info.yaml: |
    clients:
    - host: ${local.synologyCsiSettings.clientIp}
      port: ${local.synologyCsiSettings.clientPort}
      https: true
      username: ${local.synologyCsiSettings.serviceAccountUsername}
      password: ${local.synologyCsiSettings.serviceAccountPassword}
YAML
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

  depends_on = [kubectl_manifest.client-info-secret]
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
  # mount_options = ["file_mode=0700", "dir_mode=0777", "mfsymlinks", "uid=1000", "gid=1000", "nobrl", "cache=none"]
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
}

resource "helm_release" "cloudnative-pg-operator" {
  name             = local.cloudNativePGSettings.name
  repository       = local.cloudNativePGSettings.repository
  chart            = local.cloudNativePGSettings.name
  version          = local.cloudNativePGSettings.chart_version
  namespace        = local.cloudNativePGSettings.namespace
  create_namespace = true
}

resource "helm_release" "argocd" {
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

resource "kubectl_manifest" "azure-secret-sp-secret" {
    yaml_body = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: azure-secret-sp-secret
type: Opaque
stringData:
  clientId: ${var.azureServicePrincipalClientId}
  clientSecret: ${var.azureServicePrincipalClientSecret}
YAML
}

resource "kubernetes_manifest" "azure-kv-cluster-store" {
  depends_on = [kubectl_manifest.azure-secret-sp-secret]

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
            }
            clientSecret = {
              name = "azure-secret-sp-secret"
              key = "clientSecret"
            }
          }
        }
      }
    }
  }
}

# resource "kubectl_manifest" "postgres-cluster-superuser" {
#     yaml_body = <<YAML
# apiVersion: external-secrets.io/v1beta1
# kind: ClusterExternalSecret
# metadata:
#   name: postgres-cluster-superuser
# spec:
#   externalSecretName: postgres-superuser-external-secret
#   refreshTime: "1h"

#   externalSecretSpec:
#     secretStoreRef:
#       name: azure-kv-cluster-store
#       kind: ClusterSecretStore

#     refreshInterval: "36h"
#     target:
#       name: "postgres-superuser-secret"
#       template:
#         type: kubernetes.io/basic-auth

#     data:
#       - secretKey: username
#         remoteRef:
#           key: postgres-super-user
#       - secretKey: password
#         remoteRef:
#           key: postgres-super-user-password
# YAML
# depends_on = [kubernetes_manifest.synology-csi-namespace]
# }

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
