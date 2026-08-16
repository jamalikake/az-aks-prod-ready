output "namespace_scope" {
  description = "Full Azure resource scope used for the namespace-level role assignments."
  value       = local.namespace_scope
}

output "admin_assignment_ids" {
  description = "Role assignment IDs for admin principals."
  value       = { for k, v in azurerm_role_assignment.admin : k => v.id }
}

output "reader_assignment_ids" {
  description = "Role assignment IDs for reader principals."
  value       = { for k, v in azurerm_role_assignment.reader : k => v.id }
}
