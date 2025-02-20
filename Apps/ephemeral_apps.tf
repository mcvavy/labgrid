variable "apps" {
  type = map(object({
    chart_path     = string
    value_files    = list(string)
    helm_parameters = list(object({
      name  = string
      value = string
    }))
    init_command = optional(string)  # Only some apps will have this
  }))

  default = {
    "iam" = {
      chart_path  = "charts/iam"
      value_files = ["values-ephemeral.yaml"]
      helm_parameters = [
        { name = "keycloak.ingress.hostname", value = "iam-{{SANITIZED_BRANCH}}.staging.labgrid.net" },
        { name = "keycloak.ingress.extraHosts[0].name", value = "iam-{{SANITIZED_BRANCH}}.local.staging.labgrid.net" },
        { name = "keycloakCertificate.commonName", value = "iam-{{SANITIZED_BRANCH}}.local.labgrid.net" },
        { name = "keycloakCertificate.dnsNames[0]", value = "iam-{{SANITIZED_BRANCH}}.labgrid.net" },
        { name = "keycloakCertificate.dnsNames[1]", value = "iam-{{SANITIZED_BRANCH}}.local.labgrid.net" }
      ]
      init_command = <<EOT
until pg_isready -h "${RELEASE_NAME}-PGCLUSTER_RW_SERVICE_HOST" -p 5432; do
  echo Waiting for the database to be ready...;
  sleep 5;
done;
EOT
    }
  }
}

resource "argocd_application_set" "ephemeral" {
  metadata {
    name      = "ephemeral"
    namespace = "argocd"
  }

  spec {
    generators {
      git {
        repo_url = var.argocd_repo_url
        revision = "HEAD"
        branches = var.argocd_target_branches
      }
    }

    template {
      metadata {
        name = "{{app}}-ephemeral-${replace("{{branch}}", "/", "-")}"
      }

      spec {
        project = "default"
        source {
          repo_url        = "https://github.com/mcvavy/labgrid.git"
          target_revision = "{{branch}}"
          path            = lookup(var.apps, "{{app}}", null).chart_path
          helm {
            value_files = lookup(var.apps, "{{app}}", null).value_files

            dynamic "parameters" {
              for_each = lookup(var.apps, "{{app}}", null).helm_parameters
              content {
                name  = parameters.value.name
                value = replace(parameters.value.value, "{{SANITIZED_BRANCH}}",replace("{{branch}}", "/", "-"))
              }
            }

            # Conditionally inject initContainers.command if the app has an init_command
            dynamic "parameters" {
              for_each = lookup(var.apps, "{{app}}", null).init_command != null ? [lookup(var.apps, "{{app}}", null).init_command] : []
              content {
                name  = "keycloak.initContainers.command"
                value = yamlencode([
                  "sh",
                  "-c",
                  replace(
                    parameters.value,
                    "${RELEASE_NAME}",
                    upper("{{app}}-ephemeral-${replace("{{branch}}", "/", "-")}")
                  )
                ])
              }
            }
          }
        }

        destination {
          server    = "https://kubernetes.default.svc"
          namespace = "{{app}}-ephemeral-{{branch}}"
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
