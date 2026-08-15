locals {
  name_prefix = "${var.project}-${var.environment}"
  acr_suffix  = substr(replace(data.azurerm_client_config.current.subscription_id, "-", ""), 0, 6)

  common_tags = merge(var.tags, {
    environment = var.environment
    managed_by  = "terraform"
  })

  subnets = {
    "snet-aks" = {
      address_prefixes = var.aks_subnet_address_prefixes
    }
    "snet-pe" = {
      address_prefixes = var.pe_subnet_address_prefixes
    }
  }
}

module "resource_group" {
  source = "../modules/resource-group"

  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source = "../modules/network"

  resource_group_name = module.resource_group.name
  location            = var.location
  vnet_name           = "vnet-${local.name_prefix}"
  address_space       = var.vnet_address_space
  subnets             = local.subnets
  tags                = local.common_tags
}

module "log_analytics" {
  source = "../modules/log-analytics"

  name                = "log-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = var.location
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_in_days
  tags                = local.common_tags
}

module "identity" {
  source = "../modules/identity"

  name                                 = "id-${local.name_prefix}-aks"
  resource_group_name                  = module.resource_group.name
  location                             = var.location
  vnet_id                              = module.network.vnet_id
  private_dns_zone_id                  = module.network.aks_private_dns_zone_id
  private_dns_zone_contributor_enabled = true
  tags                                 = local.common_tags
}

module "key_vault" {
  source = "../modules/key-vault"

  name                          = "kv-${local.name_prefix}"
  resource_group_name           = module.resource_group.name
  location                      = var.location
  sku_name                      = var.key_vault_sku_name
  public_network_access_enabled = var.key_vault_public_network_access_enabled
  purge_protection_enabled      = var.key_vault_purge_protection_enabled
  soft_delete_retention_days    = var.key_vault_soft_delete_retention_days
  log_analytics_workspace_id    = module.log_analytics.id
  enable_diagnostics            = true
  tags                          = local.common_tags
}

module "acr" {
  source = "../modules/acr"

  name                          = "${replace("acr${local.name_prefix}", "-", "")}${local.acr_suffix}"
  resource_group_name           = module.resource_group.name
  location                      = var.location
  sku                           = var.acr_sku
  public_network_access_enabled = var.acr_public_network_access_enabled
  georeplication_locations      = var.acr_georeplication_locations
  private_endpoint_subnet_id    = var.acr_private_endpoint_enabled ? module.network.subnet_ids["snet-pe"] : null
  vnet_id                       = var.acr_private_endpoint_enabled ? module.network.vnet_id : null
  tags                          = local.common_tags
}

module "aks" {
  source = "../modules/aks"

  name                       = "aks-${local.name_prefix}"
  resource_group_name        = module.resource_group.name
  location                   = var.location
  dns_prefix                 = local.name_prefix
  kubernetes_version         = var.kubernetes_version
  sku_tier                   = var.sku_tier
  private_dns_zone_id        = module.network.aks_private_dns_zone_id
  identity_id                = module.identity.id
  vnet_subnet_id             = module.network.subnet_ids["snet-aks"]
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  admin_group_object_ids     = var.admin_group_object_ids
  automatic_channel_upgrade  = var.automatic_channel_upgrade
  log_analytics_workspace_id = module.log_analytics.id
  default_node_pool          = var.default_node_pool
  user_node_pools            = var.user_node_pools
  tags                       = local.common_tags

  # Ensures the identity's Network Contributor + Private DNS Zone Contributor
  # role assignments exist before AKS tries to join the VNet / write its DNS record.
  depends_on = [module.identity]
}

# Crosses two modules (kubelet identity only exists after the cluster is
# created, the registry is a separate module), so it lives at the parent level.
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = module.acr.id
  role_definition_name = "AcrPull"
  principal_id         = module.aks.kubelet_identity_object_id
}
