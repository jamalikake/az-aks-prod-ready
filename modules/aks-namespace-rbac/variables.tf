variable "cluster_id" {
  description = "Resource ID of the AKS cluster. Namespace-scoped role assignments are created under this ID."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to scope access to."
  type        = string
}

variable "admin_principal_ids" {
  description = "Object IDs (users, groups, service principals) granted Azure Kubernetes Service RBAC Admin on the namespace (read, write, update, delete)."
  type        = list(string)
  default     = []
}

variable "reader_principal_ids" {
  description = "Object IDs (users, groups, service principals) granted Azure Kubernetes Service RBAC Reader on the namespace (read-only)."
  type        = list(string)
  default     = []
}
