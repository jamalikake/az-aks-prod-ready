variable "project" {
  description = "Short project name used in resource naming."
  type        = string
  default     = "aks"
}

variable "environment" {
  description = "Environment name (dev, uat, prod)."
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "uksouth"
}

variable "tags" {
  description = "Extra tags merged into every resource's tags."
  type        = map(string)
  default     = {}
}

variable "vnet_address_space" {
  description = "Address space of the environment's VNet."
  type        = list(string)
}

variable "aks_subnet_address_prefixes" {
  description = "Address prefixes for the subnet AKS nodes/pods are deployed into."
  type        = list(string)
}

variable "pe_subnet_address_prefixes" {
  description = "Address prefixes for the subnet used by private endpoints (ACR, etc)."
  type        = list(string)
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs granted cluster-admin via Azure RBAC."
  type        = list(string)
  default     = []
}

variable "kubernetes_version" {
  description = "Kubernetes version. Leave null to use the current AKS default."
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "AKS control plane pricing tier: Free, Standard or Premium."
  type        = string
  default     = "Standard"
}

variable "automatic_channel_upgrade" {
  description = "Automatic upgrade channel for the cluster (patch, stable, rapid, node-image)."
  type        = string
  default     = "stable"
}

variable "default_node_pool" {
  description = "Configuration for the default (system) node pool."
  type = object({
    name                 = string
    vm_size              = string
    os_disk_size_gb      = number
    zones                = list(string)
    auto_scaling_enabled = bool
    node_count           = optional(number)
    min_count            = optional(number)
    max_count            = optional(number)
  })
}

variable "user_node_pools" {
  description = "Map of additional user node pools to create, keyed by pool name."
  type = map(object({
    vm_size              = string
    os_disk_size_gb      = number
    zones                = list(string)
    vnet_subnet_id       = optional(string)
    max_pods             = optional(number, 30)
    node_labels          = optional(map(string), {})
    node_taints          = optional(list(string), [])
    auto_scaling_enabled = bool
    node_count           = optional(number)
    min_count            = optional(number)
    max_count            = optional(number)
  }))
  default = {}
}

variable "acr_sku" {
  description = "ACR SKU."
  type        = string
  default     = "Standard"
}

variable "acr_public_network_access_enabled" {
  type    = bool
  default = true
}

variable "acr_georeplication_locations" {
  type    = list(string)
  default = []
}

variable "acr_private_endpoint_enabled" {
  type    = bool
  default = false
}

variable "key_vault_sku_name" {
  type    = string
  default = "standard"
}

variable "key_vault_public_network_access_enabled" {
  type    = bool
  default = true
}

variable "key_vault_purge_protection_enabled" {
  type    = bool
  default = false
}

variable "key_vault_soft_delete_retention_days" {
  type    = number
  default = 7
}

variable "log_analytics_sku" {
  type    = string
  default = "PerGB2018"
}

variable "log_analytics_retention_in_days" {
  type    = number
  default = 30
}
