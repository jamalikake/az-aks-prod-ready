resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = true

  # Wait for all pods to be ready before marking the release as successful.
  wait    = true
  timeout = 600

  values = concat(
    [
      yamlencode({
        global = {
          # Reduce replica count to 1 for non-HA deployments.
          replicaCount = var.ha_enabled ? 2 : 1
        }
        server = {
          service = {
            type = var.server_service_type
          }
          # Required when accessed via plain HTTP (no TLS termination at the server).
          extraArgs = ["--insecure"]
        }
        redis-ha = {
          enabled = var.ha_enabled
        }
        controller = {
          replicas = var.ha_enabled ? 2 : 1
        }
        repoServer = {
          replicas = var.ha_enabled ? 2 : 1
        }
        applicationSet = {
          replicas = var.ha_enabled ? 2 : 1
        }
      })
    ],
    var.extra_values != "" ? [var.extra_values] : []
  )
}
