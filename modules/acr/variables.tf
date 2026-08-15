variable "name" {
  description = "Name of the container registry (5-50 alphanumeric characters, globally unique)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the registry is created in."
  type        = string
}

variable "location" {
  description = "Azure region for the registry."
  type        = string
}

variable "sku" {
  description = "ACR SKU. Premium is required for private endpoints and geo-replication."
  type        = string
  default     = "Standard"
}

variable "public_network_access_enabled" {
  description = "Whether the registry is reachable over its public endpoint."
  type        = bool
  default     = true
}

variable "georeplication_locations" {
  description = "Additional Azure regions to geo-replicate the registry to (Premium SKU only)."
  type        = list(string)
  default     = []
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID to deploy a private endpoint into. Leave null to skip private endpoint creation."
  type        = string
  default     = null
}

variable "vnet_id" {
  description = "VNet ID to link the ACR private DNS zone to. Required when private_endpoint_subnet_id is set."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to the registry."
  type        = map(string)
  default     = {}
}
