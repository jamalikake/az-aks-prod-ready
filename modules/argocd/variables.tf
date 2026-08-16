variable "namespace" {
  description = "Kubernetes namespace to deploy ArgoCD into."
  type        = string
  default     = "argocd"
}

variable "chart_version" {
  description = "ArgoCD Helm chart version (argo/argo-cd). Pin this and bump intentionally."
  type        = string
  default     = "7.7.23"
}

variable "server_service_type" {
  description = "Kubernetes service type for the ArgoCD server. Use LoadBalancer for direct access, ClusterIP when fronted by an ingress."
  type        = string
  default     = "LoadBalancer"
}

variable "ha_enabled" {
  description = "Deploy ArgoCD in HA mode (multiple replicas). Disable for dev/cost-saving."
  type        = bool
  default     = false
}

variable "extra_values" {
  description = "Additional Helm values to merge, expressed as a YAML string. Applied last so they override defaults."
  type        = string
  default     = ""
}
