variable "name" {
  description = "Name of the AKS cluster."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the cluster is created in."
  type        = string
}

variable "location" {
  description = "Azure region for the cluster."
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the cluster."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version. Leave null to use the current AKS default."
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "AKS pricing tier for the control plane: Free, Standard (99.95% SLA) or Premium (long-term support)."
  type        = string
  default     = "Standard"
}

variable "node_resource_group" {
  description = "Name of the auto-generated resource group that holds node/infra resources (MC_ group). Leave null to accept the AKS default naming."
  type        = string
  default     = null
}

variable "private_cluster_enabled" {
  description = "Whether the API server is only reachable via a private endpoint."
  type        = bool
  default     = true
}

variable "private_dns_zone_id" {
  description = "ID of the privatelink.<region>.azmk8s.io private DNS zone. Required when private_cluster_enabled is true and a custom VNet is used."
  type        = string
  default     = null
}

variable "identity_id" {
  description = "ID of the user-assigned managed identity used by the AKS control plane."
  type        = string
}

variable "vnet_subnet_id" {
  description = "Subnet ID the default (system) node pool is deployed into. Also used as the default subnet for user node pools that don't specify their own."
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID used for Azure AD / Azure RBAC integration."
  type        = string
}

variable "admin_group_object_ids" {
  description = "Azure AD group object IDs granted cluster-admin via Azure RBAC."
  type        = list(string)
  default     = []
}

variable "local_account_disabled" {
  description = "Disable local Kubernetes accounts, forcing all access through Azure AD."
  type        = bool
  default     = true
}

variable "azure_policy_enabled" {
  description = "Whether the Azure Policy add-on is enabled."
  type        = bool
  default     = true
}

variable "automatic_channel_upgrade" {
  description = "Automatic upgrade channel for the Kubernetes control plane/nodes (e.g. patch, stable, rapid, node-image)."
  type        = string
  default     = "stable"
}

variable "node_os_upgrade_channel" {
  description = "Automatic upgrade channel for node OS security patches."
  type        = string
  default     = "NodeImage"
}

variable "maintenance_window" {
  description = "Optional maintenance window for control plane/node upgrades."
  type = object({
    allowed = list(object({
      day   = string
      hours = list(number)
    }))
  })
  default = null
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for the Container Insights (oms_agent) integration. Leave null to skip."
  type        = string
  default     = null
}

variable "pod_cidr" {
  description = "CIDR used for pod IPs under Azure CNI Overlay. Must not overlap the VNet address space."
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  description = "CIDR used for Kubernetes service IPs."
  type        = string
  default     = "10.245.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address (within service_cidr) used for the cluster's DNS service."
  type        = string
  default     = "10.245.0.10"
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

variable "tags" {
  description = "Tags applied to the cluster and node pools."
  type        = map(string)
  default     = {}
}
