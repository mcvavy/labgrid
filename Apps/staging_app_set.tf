resource "argocd_application_set" "staging" {
  metadata {
    name = "labgrid-staging"
  }

  spec {
    generator {
      git {
        repo_url = "https://github.com/mcvavy/labgrid.git"
        revision = "develop"

        directory {
          path = "Apps/charts/vikunja"
        }
      }
    }

    template {
      metadata {
        name = "{{path.basename}}-stg"
      }

      spec {
        project = "default"
        source {
          repo_url        = "https://github.com/mcvavy/labgrid.git"
          target_revision = "develop"
          path            = "{{path}}"

          helm {
            value_files = ["values-staging.yaml"]
          }
        }

        destination {
          server    = "https://kubernetes.default.svc"
          namespace = "{{path.basename}}-stg-system"
        }

        sync_policy {
          automated {
            prune     = true
            self_heal = true
          }
          sync_options = ["CreateNamespace=true"]
        }
      }
    }
  }
}