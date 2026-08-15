resource "azurerm_container_registry" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku

  # Managed identity + RBAC is used for image pulls (AcrPull role assignment
  # granted to the AKS kubelet identity at the environment level) - no admin
  # credentials are ever created.
  admin_enabled = false

  public_network_access_enabled = var.public_network_access_enabled

  dynamic "georeplications" {
    for_each = var.sku == "Premium" ? var.georeplication_locations : []

    content {
      location                = georeplications.value
      zone_redundancy_enabled = true
      tags                    = var.tags
    }
  }

  tags = var.tags
}

# Optional private endpoint for Premium registries so pulls stay on the
# private network instead of traversing the public ACR endpoint.
resource "azurerm_private_dns_zone" "acr" {
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "privatelink.azurecr.io"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  name                  = "link-${var.name}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "acr" {
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-${var.name}"
  resource_group_name = var.resource_group_name
  location            = var.location
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = azurerm_container_registry.this.id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.acr[0].id]
  }
}
