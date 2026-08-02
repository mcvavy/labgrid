################################################################################
# NGINX Gateway Fabric + shared labgrid-gateway + smoke HTTPRoute
# Dual-run with ingress-nginx (192.168.1.204). Gateway VIP: 192.168.1.205.
# CRDs + cert-manager --enable-gateway-api come from Base/Operators.
################################################################################

resource "helm_release" "nginx_gateway_fabric" {
  name       = local.nginxGatewayFabricSettings.name
  repository = local.nginxGatewayFabricSettings.repository
  chart      = local.nginxGatewayFabricSettings.chart
  version    = local.nginxGatewayFabricSettings.chart_version

  namespace        = local.nginxGatewayFabricSettings.namespace
  create_namespace = true
  skip_crds        = true

  values = [
    file("${path.module}/values/nginx-gateway-fabric/values.yaml")
  ]

  depends_on = [kubernetes_manifest.metallb_l2advertisement]
}

resource "kubernetes_manifest" "labgrid_gateway" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = local.nginxGatewayFabricSettings.gateway_name
      namespace = local.nginxGatewayFabricSettings.namespace
      annotations = {
        # Issues labgrid.net wildcard into labgrid-wildcard-tls.
        # tranzrmoves.com uses an explicit Certificate (different ClusterIssuer).
        "cert-manager.io/cluster-issuer" = local.nginxGatewayFabricSettings.cluster_issuer
      }
    }
    spec = {
      gatewayClassName = "nginx"
      listeners = [
        {
          name     = "http"
          port     = 80
          protocol = "HTTP"
          hostname = local.nginxGatewayFabricSettings.gateway_hostname
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
        },
        {
          name     = "https"
          port     = 443
          protocol = "HTTPS"
          hostname = local.nginxGatewayFabricSettings.gateway_hostname
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                kind = "Secret"
                name = local.nginxGatewayFabricSettings.tls_secret_name
              }
            ]
          }
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
        },
        {
          name     = local.nginxGatewayFabricSettings.tranzrmoves_http_listener
          port     = 80
          protocol = "HTTP"
          hostname = local.nginxGatewayFabricSettings.tranzrmoves_gateway_hostname
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
        },
        {
          name     = local.nginxGatewayFabricSettings.tranzrmoves_https_listener
          port     = 443
          protocol = "HTTPS"
          hostname = local.nginxGatewayFabricSettings.tranzrmoves_gateway_hostname
          tls = {
            mode = "Terminate"
            certificateRefs = [
              {
                kind = "Secret"
                name = local.nginxGatewayFabricSettings.tranzrmoves_tls_secret_name
              }
            ]
          }
          allowedRoutes = {
            namespaces = {
              from = "All"
            }
          }
        }
      ]
    }
  }

  depends_on = [
    helm_release.nginx_gateway_fabric,
    kubernetes_manifest.letsencrypt-production,
    kubernetes_manifest.tranzrmoves_wildcard_certificate
  ]
}

################################################################################
# Explicit Certificate for *.tranzrmoves.com (tranzr DNS-01 issuer).
# Cannot use the Gateway's single cert-manager.io/cluster-issuer annotation.
################################################################################

resource "kubernetes_manifest" "tranzrmoves_wildcard_certificate" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = local.nginxGatewayFabricSettings.tranzrmoves_tls_secret_name
      namespace = local.nginxGatewayFabricSettings.namespace
    }
    spec = {
      secretName = local.nginxGatewayFabricSettings.tranzrmoves_tls_secret_name
      issuerRef = {
        name  = local.nginxGatewayFabricSettings.tranzrmoves_cluster_issuer
        kind  = "ClusterIssuer"
        group = "cert-manager.io"
      }
      dnsNames = [
        local.nginxGatewayFabricSettings.tranzrmoves_gateway_hostname
      ]
    }
  }

  depends_on = [
    helm_release.nginx_gateway_fabric,
    kubernetes_manifest.tranzr-letsencrypt-production
  ]
}

################################################################################
# Smoke test: gateway-test.labgrid.net → echo backend via HTTPRoute
# Point Cloudflare A record for gateway-test.labgrid.net at 192.168.1.205.
################################################################################

resource "kubernetes_namespace_v1" "gateway_smoke" {
  metadata {
    name = "gateway-smoke"
    labels = {
      "app.kubernetes.io/name"       = "gateway-smoke"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_deployment_v1" "gateway_smoke" {
  metadata {
    name      = "gateway-smoke"
    namespace = kubernetes_namespace_v1.gateway_smoke.metadata[0].name
    labels = {
      app = "gateway-smoke"
    }
  }

  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "gateway-smoke"
      }
    }
    template {
      metadata {
        labels = {
          app = "gateway-smoke"
        }
      }
      spec {
        container {
          name  = "echo"
          image = "registry.k8s.io/e2e-test-images/agnhost:2.53"
          args  = ["netexec", "--http-port=8080"]
          port {
            container_port = 8080
            name           = "http"
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "gateway_smoke" {
  metadata {
    name      = "gateway-smoke"
    namespace = kubernetes_namespace_v1.gateway_smoke.metadata[0].name
    labels = {
      app = "gateway-smoke"
    }
  }

  spec {
    selector = {
      app = "gateway-smoke"
    }
    port {
      name        = "http"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
  }
}

resource "kubernetes_manifest" "gateway_smoke_httproute" {
  manifest = {
    apiVersion = "gateway.networking.k8s.io/v1"
    kind       = "HTTPRoute"
    metadata = {
      name      = "gateway-smoke"
      namespace = kubernetes_namespace_v1.gateway_smoke.metadata[0].name
    }
    spec = {
      parentRefs = [
        {
          name      = local.nginxGatewayFabricSettings.gateway_name
          namespace = local.nginxGatewayFabricSettings.namespace
        }
      ]
      hostnames = ["gateway-test.labgrid.net"]
      rules = [
        {
          matches = [
            {
              path = {
                type  = "PathPrefix"
                value = "/"
              }
            }
          ]
          backendRefs = [
            {
              name = kubernetes_service_v1.gateway_smoke.metadata[0].name
              port = 80
            }
          ]
        }
      ]
    }
  }

  depends_on = [
    kubernetes_manifest.labgrid_gateway,
    kubernetes_deployment_v1.gateway_smoke,
    kubernetes_service_v1.gateway_smoke
  ]
}
