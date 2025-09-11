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

resource "kubernetes_secret_v1" "tranzr-cloudflare_token_secret" {
  depends_on = [ kubernetes_manifest.metallb_l2advertisement ]

  metadata {
    name = "tranzr-cloudflare-token-secret"
    namespace = "${local.certManagerSettings.namespace}"
  }

  data = {
    cloudflare-token: "${var.tranzrCloudflareApiTokenKey}"
  }

  type = "Opaque"
}

resource "kubernetes_manifest" "letsencrypt-staging" {
  depends_on = [kubernetes_secret_v1.cloudflare_token_secret]

  manifest = {
    apiVersion = local.clusterIssuerSettings.apiVersion
    kind       = local.clusterIssuerSettings.kind
    metadata = {
      name = local.clusterIssuerSettings.nameStaging
    }
    spec = {
      acme = {
        server  = local.clusterIssuerSettings.stagingServer
        email   = local.clusterIssuerSettings.email
        privateKeySecretRef = {
          name = local.clusterIssuerSettings.nameStaging
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

resource "kubernetes_manifest" "tranzr-letsencrypt-staging" {
  depends_on = [kubernetes_secret_v1.cloudflare_token_secret]

  manifest = {
    apiVersion = local.clusterIssuerSettings.apiVersion
    kind       = local.clusterIssuerSettings.kind
    metadata = {
      name = local.clusterIssuerSettings.tranzrNameStaging
    }
    spec = {
      acme = {
        server  = local.clusterIssuerSettings.stagingServer
        email   = local.clusterIssuerSettings.email
        privateKeySecretRef = {
          name = local.clusterIssuerSettings.tranzrNameStaging
        }
        solvers = [{
          dns01 = {
            cloudflare = {
              email = local.clusterIssuerSettings.email
              apiTokenSecretRef = {
                name = "tranzr-cloudflare-token-secret"
                key  = "cloudflare-token"
              }
            }
          }
          selector = {
            dnsZones = [var.tranzrDnsZones]
          }
        }]
      }
    }
  }
}

resource "kubernetes_manifest" "letsencrypt-production" {
  depends_on = [kubernetes_secret_v1.cloudflare_token_secret]

  manifest = {
    apiVersion = local.clusterIssuerSettings.apiVersion
    kind       = local.clusterIssuerSettings.kind
    metadata = {
      name = local.clusterIssuerSettings.nameProduction
    }
    spec = {
      acme = {
        server  = local.clusterIssuerSettings.productionServer
        email   = local.clusterIssuerSettings.email
        privateKeySecretRef = {
          name = local.clusterIssuerSettings.nameProduction
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

resource "kubernetes_manifest" "tranzr-letsencrypt-production" {
  depends_on = [kubernetes_secret_v1.cloudflare_token_secret]

  manifest = {
    apiVersion = local.clusterIssuerSettings.apiVersion
    kind       = local.clusterIssuerSettings.kind
    metadata = {
      name = local.clusterIssuerSettings.tranzrNameProduction
    }
    spec = {
      acme = {
        server  = local.clusterIssuerSettings.productionServer
        email   = local.clusterIssuerSettings.email
        privateKeySecretRef = {
          name = local.clusterIssuerSettings.tranzrNameProduction
        }
        solvers = [{
          dns01 = {
            cloudflare = {
              email = local.clusterIssuerSettings.email
              apiTokenSecretRef = {
                name = "tranzr-cloudflare-token-secret"
                key  = "cloudflare-token"
              }
            }
          }
          selector = {
            dnsZones = [var.tranzrDnsZones]
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

# resource "kubernetes_secret_v1" "client-info-secret" {
#   metadata {
#     name = "client-info-secret"
#   }

#   data = {
#     host = local.synologyCsiSettings.clientIp
#     port = local.synologyCsiSettings.clientPort
#     https = true
#     username = local.synologyCsiSettings.serviceAccountUsername
#     password = local.synologyCsiSettings.serviceAccountPassword
#   }

#   type = "Opaque"

#   depends_on = [kubernetes_manifest.synology-csi-namespace]
# }


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
}

resource "kubernetes_storage_class_v1" "synology-nfs-delete" {
  metadata {
    name = "synology-nfs-delete"
    annotations = {
      "storageclass.kubernetes.io/is-default-class" = "true"
    }
  }
  storage_provisioner = "csi.san.synology.com"
  reclaim_policy      = "Delete"
  allow_volume_expansion = true
  parameters = {
    dsm = var.synologyClientIp
    location = "/volume1"
    protocol = "nfs"
    mountPermissions = "0775"
  }
  mount_options = ["nfsvers=4.1"]
}

resource "kubectl_manifest" "synology-snapshot-class" {
    yaml_body = <<YAML
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: synology-snapshotclass
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
driver: csi.san.synology.com
deletionPolicy: Delete
YAML
depends_on = [  kubernetes_manifest.synology-csi-namespace ]
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

resource "kubernetes_manifest" "pg-admin-namespace" {
  manifest = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = local.pgAdminSettings.namespace
    }
  }
}

resource "kubernetes_manifest" "pg-admin-password" {
  depends_on = [ kubernetes_manifest.pg-admin-namespace ]

  manifest = {
    apiVersion = "external-secrets.io/v1beta1"
    kind       = "ExternalSecret"
    metadata = {
      name = "pg-admin-password"
      namespace = kubernetes_manifest.pg-admin-namespace.manifest.metadata.name
    }
    spec = {
      secretStoreRef = {
        name = "azure-kv-cluster-store"
        kind = "ClusterSecretStore"
      }
      refreshInterval = "36h"
      target = {
        name     = "pg-admin-password-secret"
        template = {
          type = "kubernetes.io/basic-auth"
        }
      }
      data = [
        {
          secretKey = "password"
          remoteRef = {
            key = "pg-admin-password"
          }
        }
      ]
    }
  }
}

resource "helm_release" "pgadmin" {
  depends_on = [ kubernetes_manifest.pg-admin-password ]

  name             = local.pgAdminSettings.name
  repository       = local.pgAdminSettings.repository
  chart            = local.pgAdminSettings.name
  namespace        = kubernetes_manifest.pg-admin-namespace.manifest.metadata.name
  version          = local.pgAdminSettings.chart_version

  values = [ 
    file("${path.module}/values/pgadmin/values.yaml") 
    ]
}

resource "helm_release" "prometheus" {
  depends_on = [ kubernetes_manifest.metallb_l2advertisement ]

  name             = local.prometheusSettings.name
  repository       = local.prometheusSettings.repository
  chart            = local.prometheusSettings.name
  namespace        = local.prometheusSettings.namespace
  version          = local.prometheusSettings.chart_version
  create_namespace = true

  values = [ 
    file("${path.module}/values/prometheus/values.yaml") 
    ]
}
