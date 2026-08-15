resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.user_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  vnet_subnet_id        = coalesce(each.value.vnet_subnet_id, var.vnet_subnet_id)
  zones                 = each.value.zones
  os_disk_size_gb       = each.value.os_disk_size_gb
  mode                  = "User"
  max_pods              = each.value.max_pods
  node_labels           = each.value.node_labels
  node_taints           = each.value.node_taints

  auto_scaling_enabled = each.value.auto_scaling_enabled
  node_count           = each.value.auto_scaling_enabled ? null : each.value.node_count
  min_count            = each.value.auto_scaling_enabled ? each.value.min_count : null
  max_count            = each.value.auto_scaling_enabled ? each.value.max_count : null

  upgrade_settings {
    max_surge = "10%"
  }

  tags = var.tags
}
