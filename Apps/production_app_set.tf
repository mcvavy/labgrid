resource "argocd_application_set" "production" {
  metadata {
    name = "labgrid-production"
  }

  spec {
    generator {
      git {
        repo_url = "https://github.com/mcvavy/labgrid.git"
        revision = "release"

        directory {
          path = "Apps/charts/*"
        }
      }
    }

    template {
      metadata {
        name = "{{path.basename}}"
      }

      spec {
        project = "default"
        source {
          repo_url        = "https://github.com/mcvavy/labgrid.git"
          target_revision = "release"
          path            = "{{path}}"

          helm {
            value_files = ["values-production.yaml"]
          }
        }

        destination {
          server    = "https://kubernetes.default.svc"
          namespace = "{{path.basename}}-system"
        }

        sync_policy {
          automated {
            prune     = false
            self_heal = true
          }
          sync_options = ["CreateNamespace=true"]
        }
      }
    }
  }
}