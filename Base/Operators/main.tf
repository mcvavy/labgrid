

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

################################################################################
# Step 1: Fetch CRD YAMLs from GitHub
################################################################################

data "http" "snapshot_crd_volumesnapshotclasses" {
  method = "GET"
  url = "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshotclasses.yaml"
}

data "http" "snapshot_crd_volumesnapshotcontents" {
  method = "GET"
  url = "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshotcontents.yaml"
}

data "http" "snapshot_crd_volumesnapshots" {
  method = "GET"
  url = "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/client/config/crd/snapshot.storage.k8s.io_volumesnapshots.yaml"
}

################################################################################
# Step 2: Apply the CRDs
################################################################################

resource "kubectl_manifest" "snapshot_crd_volumesnapshotclasses" {
  yaml_body = data.http.snapshot_crd_volumesnapshotclasses.response_body
}

resource "kubectl_manifest" "snapshot_crd_volumesnapshotcontents" {
  yaml_body = data.http.snapshot_crd_volumesnapshotcontents.response_body
}

resource "kubectl_manifest" "snapshot_crd_volumesnapshots" {
  yaml_body = data.http.snapshot_crd_volumesnapshots.response_body
}

################################################################################
# Step 3: Fetch & Install the Snapshot Controller (RBAC + Deployment)
################################################################################

data "http" "snapshot_controller_rbac" {
  method = "GET"
  url = "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/rbac-snapshot-controller.yaml"
}

data "http" "snapshot_controller_setup" {
  method = "GET"
  url = "https://raw.githubusercontent.com/kubernetes-csi/external-snapshotter/master/deploy/kubernetes/snapshot-controller/setup-snapshot-controller.yaml"
}

resource "kubectl_manifest" "snapshot_controller_rbac" {
  yaml_body = data.http.snapshot_controller_rbac.response_body
  depends_on = [
    kubectl_manifest.snapshot_crd_volumesnapshotclasses,
    kubectl_manifest.snapshot_crd_volumesnapshotcontents,
    kubectl_manifest.snapshot_crd_volumesnapshots
  ]
}

resource "kubectl_manifest" "snapshot_controller_setup" {
  yaml_body = data.http.snapshot_controller_setup.response_body
  depends_on = [
    kubectl_manifest.snapshot_controller_rbac
  ]
}
