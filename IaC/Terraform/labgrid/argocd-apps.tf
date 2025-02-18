# Public Git repository
resource "argocd_repository" "labgrid-git" {
  repo = "https://github.com/mcvavy/labgrid.git"
}

resource "kubernetes_manifest" "labgrid-iam-namespace" {
  manifest = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name = "labgrid-iam-system"
    }
  }
}

resource "argocd_application" "labgrid-iam" {
    
  depends_on = [ argocd_repository.labgrid-git, kubernetes_manifest.labgrid-iam-namespace ]

  metadata {
    name      = "labgrid-iam"
    namespace = "argocd"
  }

  spec {
    project = "default"

    source {
      repo_url        = "https://github.com/mcvavy/labgrid.git"
      path            = "Apps/IAM"
      target_revision = "feature/labgrid-iam-solution"

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
