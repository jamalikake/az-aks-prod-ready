output "namespace" {
  description = "Namespace ArgoCD was deployed into."
  value       = helm_release.argocd.namespace
}

output "name" {
  description = "Helm release name."
  value       = helm_release.argocd.name
}

output "chart_version" {
  description = "Deployed chart version."
  value       = helm_release.argocd.version
}
