variable "name" {
  description = "Name of the user-assigned managed identity."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the identity is created in."
  type        = string
}

variable "location" {
  description = "Azure region for the identity."
  type        = string
}

variable "vnet_id" {
  description = "ID of the VNet the AKS cluster is deployed into, used to scope the Network Contributor role assignment."
  type        = string
}

variable "private_dns_zone_id" {
  description = "ID of the BYO private DNS zone for a private AKS cluster."
  type        = string
  default     = null
}

variable "private_dns_zone_contributor_enabled" {
  description = "Whether to create the Private DNS Zone Contributor role assignment. Must be a static bool (not derived from a resource output) so Terraform can evaluate it at plan time."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the identity."
  type        = map(string)
  default     = {}
}
