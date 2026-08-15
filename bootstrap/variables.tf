variable "resource_group_name" {
  description = "Name of the resource group that holds the Terraform state storage account."
  type        = string
  default     = "rg-tfstate-aks"
}

variable "location" {
  description = "Azure region for the state storage account."
  type        = string
  default     = "uksouth"
}

variable "storage_account_name" {
  description = "Globally-unique name of the storage account used for remote state (3-24 lowercase alphanumeric characters)."
  type        = string
}

variable "container_name" {
  description = "Blob container name that holds the per-environment state files."
  type        = string
  default     = "tfstate"
}

variable "tags" {
  description = "Tags applied to the bootstrap resources."
  type        = map(string)
  default = {
    managed_by = "terraform"
    purpose    = "tfstate"
  }
}
