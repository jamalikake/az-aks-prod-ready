variable "resource_group_name" {
  description = "Resource group the network resources are created in."
  type        = string
}

variable "location" {
  description = "Azure region for the network resources."
  type        = string
}

variable "vnet_name" {
  description = "Name of the virtual network."
  type        = string
}

variable "address_space" {
  description = "Address space of the virtual network."
  type        = list(string)
}

variable "subnets" {
  description = "Map of subnets to create, keyed by subnet name."
  type = map(object({
    address_prefixes  = list(string)
    service_endpoints = optional(list(string), [])
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = list(string)
    }))
    extra_nsg_rules = optional(list(object({
      name                   = string
      priority               = number
      direction              = string
      access                 = string
      protocol               = string
      destination_port_range = string
      source_address_prefix  = string
    })), [])
  }))
}

variable "create_aks_private_dns_zone" {
  description = "Whether to create the privatelink.<region>.azmk8s.io zone for a private AKS cluster."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the network resources."
  type        = map(string)
  default     = {}
}
