resource "azurerm_user_assigned_identity" "aks" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}

# AKS control plane identity needs Network Contributor on the VNet since the
# cluster is deployed into a pre-existing, custom VNet rather than a
# managed one.
resource "azurerm_role_assignment" "network_contributor" {
  scope                = var.vnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}

# Required for a private cluster using a bring-your-own private DNS zone:
# the control plane identity must be able to create the A record for the
# API server in that zone.
resource "azurerm_role_assignment" "private_dns_zone_contributor" {
  count = var.private_dns_zone_id != null ? 1 : 0

  scope                = var.private_dns_zone_id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.aks.principal_id
}
