resource "kubernetes_cluster_role_v1" "github_actions_admin" {
  metadata {
    name = "github-actions-admin"
  }

  rule {
    api_groups = ["*"]  # All API groups
    resources  = ["*"]  # All resources
    verbs      = ["*"]  # All actions
  }

  rule {
    non_resource_urls = ["*"]  # All non-resource URLs
    verbs             = ["*"]  # All actions
  }
}

resource "kubernetes_cluster_role_binding_v1" "github_actions_admin_binding" {
  depends_on = [ kubernetes_cluster_role_v1.github_actions_admin ]
  metadata {
    name = "github-actions-admin-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.github_actions_admin.metadata[0].name  # Reference the custom ClusterRole
  }

  subject {
    kind      = "User"
    name      = "https://iam.labgrid.net/realms/labgrid#service-account-github-actions"  # Matches the `sub` claim in the OIDC token
    api_group = "rbac.authorization.k8s.io"
  }
}