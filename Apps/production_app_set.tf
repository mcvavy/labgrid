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
          # Avoid ServerSideApply: Argo CD v2.14 static schemas lack newer K8s fields
          # (e.g. Deployment status.terminatingReplicas on 1.36), which causes
          # ComparisonError and blocks sync for apps like monitoring.
          sync_options = ["CreateNamespace=true"]
        }
      }
    }
  }
}