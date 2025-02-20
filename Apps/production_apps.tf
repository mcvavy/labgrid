variable "apps" {
  type    = list(string)
  default = ["iam"]
}

resource "argocd_application" "production" {
  for_each = toset(var.apps)

  metadata {
    name      = "${each.value}-production"
    namespace = "argocd"
  }

  spec {
    project = "default"

    source {
      repo_url        = "https://github.com/mcvavy/labgrid.git"
      target_revision = "main"
      path            = "charts/${each.value}"
      helm {
        value_files = ["values-production.yaml"]
      }
    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "${each.value}-system-production"
    }

    sync_policy {
      automated {
        prune     = false  # Avoid accidental deletions in production
        self_heal = true
      }
      sync_options = ["CreateNamespace=true"]
    }
  }
}
