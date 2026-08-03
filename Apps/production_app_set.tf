resource "argocd_application_set" "production" {
  metadata {
    name = "labgrid-production"
  }

  spec {
    generator {
      git {
        repo_url = "https://github.com/mcvavy/labgrid.git"
        revision = "main"

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
          target_revision = "main"
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
          # ServerSideApply needs Argo CD ≥3.3 on k3s 1.36 (static schema includes
          # Deployment.status.terminatingReplicas). Chart pin: Base argocd 10.2.2 / v3.4.6.
          sync_options = ["CreateNamespace=true", "ServerSideApply=true"]
        }
      }
    }
  }
}