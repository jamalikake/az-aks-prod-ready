output "id" {
  value = azurerm_user_assigned_identity.aks.id
}

output "principal_id" {
  value = azurerm_user_assigned_identity.aks.principal_id
}

output "client_id" {
  value = azurerm_user_assigned_identity.aks.client_id
}
