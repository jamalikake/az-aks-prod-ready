variable "name" {
  description = "Name of the Key Vault (3-24 alphanumeric characters, globally unique)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the Key Vault is created in."
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault."
  type        = string
}

variable "sku_name" {
  description = "Key Vault SKU."
  type        = string
  default     = "standard"
}

variable "public_network_access_enabled" {
  description = "Whether the Key Vault is reachable over its public endpoint."
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Whether purge protection is enabled. Should be true in production."
  type        = bool
  default     = false
}

variable "soft_delete_retention_days" {
  description = "Soft-delete retention period in days."
  type        = number
  default     = 7
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID to send diagnostic logs to."
  type        = string
  default     = null
}

variable "enable_diagnostics" {
  description = "Whether to create the diagnostic setting. Must be a static bool (not derived from a resource output) so Terraform can evaluate it at plan time."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags applied to the Key Vault."
  type        = map(string)
  default     = {}
}
