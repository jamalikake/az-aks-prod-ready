output "resource_group_name" {
  value = module.resource_group.name
}

output "aks_cluster_name" {
  value = module.aks.name
}

output "aks_oidc_issuer_url" {
  value = module.aks.oidc_issuer_url
}

output "acr_login_server" {
  value = module.acr.login_server
}

output "key_vault_uri" {
  value = module.key_vault.vault_uri
}

output "get_credentials_command" {
  description = "Command to fetch Azure AD-based kubeconfig for this cluster."
  value       = "az aks get-credentials --resource-group ${module.resource_group.name} --name ${module.aks.name} --overwrite-existing"
}
