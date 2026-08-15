output "id" {
  value = azurerm_kubernetes_cluster.this.id
}

output "name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "kubelet_identity_object_id" {
  description = "Object ID of the auto-provisioned kubelet identity - used to grant AcrPull on the registry."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity[0].object_id
}

output "oidc_issuer_url" {
  value = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "node_resource_group" {
  value = azurerm_kubernetes_cluster.this.node_resource_group
}

# No kube_config/kube_config_raw output: local_account_disabled = true means
# the cluster has no static admin credentials. Access is via Azure AD -
# `az aks get-credentials` + kubelogin - see the environment README.
