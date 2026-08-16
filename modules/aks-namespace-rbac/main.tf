# Namespace-scoped Azure RBAC for AKS (azure_rbac_enabled = true clusters).
# Scope format: <cluster_id>/namespaces/<namespace>
#
# Azure Kubernetes Service RBAC Admin  → read / write / update / delete
# Azure Kubernetes Service RBAC Reader → read-only

locals {
  namespace_scope = "${var.cluster_id}/namespaces/${var.namespace}"
}

resource "azurerm_role_assignment" "admin" {
  for_each = toset(var.admin_principal_ids)

  scope                = local.namespace_scope
  role_definition_name = "Azure Kubernetes Service RBAC Admin"
  principal_id         = each.value
}

resource "azurerm_role_assignment" "reader" {
  for_each = toset(var.reader_principal_ids)

  scope                = local.namespace_scope
  role_definition_name = "Azure Kubernetes Service RBAC Reader"
  principal_id         = each.value
}
