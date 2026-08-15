project     = "aks"
environment = "uat"
location    = "uksouth"

tags = {
  owner       = "platform-team"
  cost_center = "eng-uat"
}

vnet_address_space          = ["10.20.0.0/16"]
aks_subnet_address_prefixes = ["10.20.0.0/22"]
pe_subnet_address_prefixes  = ["10.20.4.0/24"]

# Fill in with the Azure AD group object ID(s) that should get cluster-admin
# via Azure RBAC, e.g. ["00000000-0000-0000-0000-000000000000"]
admin_group_object_ids = []

kubernetes_version        = null # use current AKS default
sku_tier                  = "Standard"
automatic_channel_upgrade = "stable"

default_node_pool = {
  name                 = "system"
  vm_size              = "Standard_D4s_v3"
  os_disk_size_gb      = 128
  zones                = ["1", "2", "3"]
  auto_scaling_enabled = true
  min_count            = 2
  max_count            = 4
}

user_node_pools = {
  apps = {
    vm_size              = "Standard_D4s_v3"
    os_disk_size_gb      = 128
    zones                = ["1", "2", "3"]
    auto_scaling_enabled = true
    min_count            = 2
    max_count            = 6
    node_labels          = { workload = "apps" }
  }
}

acr_sku                           = "Standard"
acr_public_network_access_enabled = true
acr_georeplication_locations      = []
acr_private_endpoint_enabled      = false

key_vault_sku_name                      = "standard"
key_vault_public_network_access_enabled = true
key_vault_purge_protection_enabled      = true
key_vault_soft_delete_retention_days    = 30

log_analytics_sku               = "PerGB2018"
log_analytics_retention_in_days = 60
