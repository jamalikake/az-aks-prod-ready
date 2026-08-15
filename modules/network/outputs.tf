output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet name to subnet ID."
  value       = { for name, subnet in azurerm_subnet.this : name => subnet.id }
}

output "nsg_ids" {
  description = "Map of subnet name to associated NSG ID."
  value       = { for name, nsg in azurerm_network_security_group.this : name => nsg.id }
}

output "aks_private_dns_zone_id" {
  value = var.create_aks_private_dns_zone ? azurerm_private_dns_zone.aks[0].id : null
}

output "aks_private_dns_zone_name" {
  value = var.create_aks_private_dns_zone ? azurerm_private_dns_zone.aks[0].name : null
}
