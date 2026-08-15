project     = "aks"
environment = "prod"
location    = "uksouth"

tags = {
  owner       = "platform-team"
  cost_center = "eng-prod"
}

vnet_address_space          = ["10.30.0.0/16"]
aks_subnet_address_prefixes = ["10.30.0.0/22"]
pe_subnet_address_prefixes  = ["10.30.4.0/24"]

# Fill in with the Azure AD group object ID(s) that should get cluster-admin
# via Azure RBAC, e.g. ["00000000-0000-0000-0000-000000000000"]
admin_group_object_ids = []

kubernetes_version        = null       # use current AKS default
sku_tier                  = "Standard" # bump to "Premium" if long-term support is required
automatic_channel_upgrade = "stable"

default_node_pool = {
  name                 = "system"
  vm_size              = "Standard_D4s_v3"
  os_disk_size_gb      = 128
  zones                = ["1", "2", "3"]
  auto_scaling_enabled = true
  min_count            = 3
  max_count            = 6
}

user_node_pools = {
  apps = {
    vm_size              = "Standard_D8s_v3"
    os_disk_size_gb      = 128
    zones                = ["1", "2", "3"]
    auto_scaling_enabled = true
    min_count            = 3
    max_count            = 12
    node_labels          = { workload = "apps" }
  }
}

acr_sku                           = "Premium"
acr_public_network_access_enabled = false
acr_georeplication_locations      = []
acr_private_endpoint_enabled      = true

# NOTE: the key-vault module does not provision a private endpoint, so
# public_network_access_enabled must stay true or the vault becomes
# unreachable (including from Terraform itself). Lock it down further with
# ip_rules/vnet rules or extend the module with a private endpoint if
# stricter network isolation is required.
key_vault_sku_name                      = "standard"
key_vault_public_network_access_enabled = true
key_vault_purge_protection_enabled      = true
key_vault_soft_delete_retention_days    = 90

log_analytics_sku               = "PerGB2018"
log_analytics_retention_in_days = 90
