# Public Git repository
resource "argocd_repository" "labgrid-git" {
  repo = "https://github.com/mcvavy/labgrid.git"
}

resource "argocd_application" "vbox_admin_tool" {
    
  depends_on = [ argocd_repository.labgrid-git ]

  metadata {
    name      = "vbox-admin-tool"
    namespace = "argocd"
  }

  spec {
    project = "default"

    source {
      repo_url        = "https://github.com/mcvavy/labgrid.git"
      path            = "Apps/IAM"
      target_revision = "main"

      helm {
        release_name = "labgrid-iam"
        value_files  = ["values.yaml"]
      }
    }

    destination {
      server    = "https://kubernetes.default.svc"
      namespace = "labgrid-iam-system"
    }

    sync_policy {
      automated {
        prune      = true
        self_heal  = true
      }
    }
  }
}
