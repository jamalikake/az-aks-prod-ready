resource "azurerm_kubernetes_cluster" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier
  node_resource_group = var.node_resource_group

  private_cluster_enabled             = var.private_cluster_enabled
  private_dns_zone_id                 = var.private_cluster_enabled ? var.private_dns_zone_id : null
  private_cluster_public_fqdn_enabled = false

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  azure_policy_enabled      = var.azure_policy_enabled
  automatic_upgrade_channel = var.automatic_channel_upgrade
  node_os_upgrade_channel   = var.node_os_upgrade_channel
  local_account_disabled    = var.local_account_disabled

  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  default_node_pool {
    name                         = var.default_node_pool.name
    vm_size                      = var.default_node_pool.vm_size
    vnet_subnet_id               = var.vnet_subnet_id
    zones                        = var.default_node_pool.zones
    os_disk_size_gb              = var.default_node_pool.os_disk_size_gb
    only_critical_addons_enabled = true
    auto_scaling_enabled         = var.default_node_pool.auto_scaling_enabled
    node_count                   = var.default_node_pool.auto_scaling_enabled ? null : var.default_node_pool.node_count
    min_count                    = var.default_node_pool.auto_scaling_enabled ? var.default_node_pool.min_count : null
    max_count                    = var.default_node_pool.auto_scaling_enabled ? var.default_node_pool.max_count : null

    upgrade_settings {
      max_surge = "10%"
    }

    tags = var.tags
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"
    load_balancer_sku   = "standard"
    pod_cidr            = var.pod_cidr
    service_cidr        = var.service_cidr
    dns_service_ip      = var.dns_service_ip
  }

  azure_active_directory_role_based_access_control {
    tenant_id              = var.tenant_id
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
  }

  dynamic "oms_agent" {
    for_each = var.log_analytics_workspace_id != null ? [1] : []

    content {
      log_analytics_workspace_id = var.log_analytics_workspace_id
    }
  }

  dynamic "maintenance_window" {
    for_each = var.maintenance_window != null ? [var.maintenance_window] : []

    content {
      dynamic "allowed" {
        for_each = maintenance_window.value.allowed

        content {
          day   = allowed.value.day
          hours = allowed.value.hours
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      kubernetes_version, # allow cluster to be upgraded out-of-band via automatic_channel_upgrade
    ]
  }

  tags = var.tags
}
