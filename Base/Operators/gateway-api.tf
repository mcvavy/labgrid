################################################################################
# Gateway API (standard channel) + NGINX Gateway Fabric CRDs
# Applied via data.http + kubectl_manifest (same pattern as CSI snapshot CRDs).
# Pin: NGF v2.5.0 → Gateway API v1.5.1 (matches Hetzner).
################################################################################

locals {
  gateway_api_crd_base = "https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${local.nginxGatewayFabricSettings.gateway_api_version}/config/crd/standard"
  gateway_api_crd_files = [
    "gateway.networking.k8s.io_backendtlspolicies.yaml",
    "gateway.networking.k8s.io_gatewayclasses.yaml",
    "gateway.networking.k8s.io_gateways.yaml",
    "gateway.networking.k8s.io_grpcroutes.yaml",
    "gateway.networking.k8s.io_httproutes.yaml",
    "gateway.networking.k8s.io_listenersets.yaml",
    "gateway.networking.k8s.io_referencegrants.yaml",
    "gateway.networking.k8s.io_tlsroutes.yaml",
  ]
}

data "http" "gateway_api_crds" {
  for_each = toset(local.gateway_api_crd_files)
  method   = "GET"
  url      = "${local.gateway_api_crd_base}/${each.value}"
}

resource "kubectl_manifest" "gateway_api_crds" {
  for_each = data.http.gateway_api_crds

  yaml_body         = each.value.response_body
  server_side_apply = true
  force_conflicts   = true
}

# ValidatingAdmissionPolicy + Binding (multi-doc)
data "http" "gateway_api_vap_safe_upgrades" {
  method = "GET"
  url    = "${local.gateway_api_crd_base}/gateway.networking.k8s.io_vap_safeupgrades.yaml"
}

locals {
  gateway_api_vap_docs = [
    for doc in split("---", data.http.gateway_api_vap_safe_upgrades.response_body) : trimspace(doc)
    if trimspace(doc) != "" && can(yamldecode(trimspace(doc)))
  ]
}

resource "kubectl_manifest" "gateway_api_vap_safe_upgrades" {
  for_each = {
    for idx, doc in local.gateway_api_vap_docs : tostring(idx) => doc
  }

  yaml_body         = each.value
  server_side_apply = true
  force_conflicts   = true

  depends_on = [kubectl_manifest.gateway_api_crds]
}

# NGF CRDs (gateway.nginx.org) — multi-doc bundle
data "http" "nginx_gateway_fabric_crds" {
  method = "GET"
  url    = "https://raw.githubusercontent.com/nginx/nginx-gateway-fabric/v${local.nginxGatewayFabricSettings.version}/deploy/crds.yaml"
}

locals {
  nginx_gateway_fabric_crd_docs = [
    for doc in split("---", data.http.nginx_gateway_fabric_crds.response_body) : trimspace(doc)
    if trimspace(doc) != "" && can(yamldecode(trimspace(doc)))
  ]
}

resource "kubectl_manifest" "nginx_gateway_fabric_crds" {
  for_each = {
    for idx, doc in local.nginx_gateway_fabric_crd_docs : tostring(idx) => doc
  }

  yaml_body         = each.value
  server_side_apply = true
  force_conflicts   = true

  depends_on = [kubectl_manifest.gateway_api_crds]
}
